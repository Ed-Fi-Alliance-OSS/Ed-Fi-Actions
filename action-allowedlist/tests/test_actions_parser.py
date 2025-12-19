import json
import pytest
import tempfile
import os
from pathlib import Path
from unittest.mock import patch, mock_open
import yaml

from action_allowedlist.actions_parser import (
    load_json_file,
    load_yaml_file,
    get_actions_from_file,
    get_all_used_actions,
    invoke_validate_actions,
)


class TestLoadJsonFile:
    """Test cases for load_json_file function."""

    def test_load_valid_json_file(self):
        """Test loading a valid JSON file."""
        test_data = {"test": "data", "number": 123}
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(test_data, f)
            temp_file = f.name
        
        try:
            result = load_json_file(temp_file)
            assert result == test_data
        finally:
            os.unlink(temp_file)

    def test_load_json_file_not_found(self):
        """Test loading a non-existent JSON file."""
        with pytest.raises(FileNotFoundError):
            load_json_file("non_existent_file.json")

    def test_load_invalid_json_file(self):
        """Test loading an invalid JSON file."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            f.write("invalid json content {")
            temp_file = f.name
        
        try:
            with pytest.raises(json.JSONDecodeError):
                load_json_file(temp_file)
        finally:
            os.unlink(temp_file)


class TestLoadYamlFile:
    """Test cases for load_yaml_file function."""

    def test_load_valid_yaml_file(self):
        """Test loading a valid YAML file."""
        test_data = {"test": "data", "list": [1, 2, 3]}
        
        with tempfile.NamedTemporaryFile(mode='w', suffix='.yml', delete=False) as f:
            yaml.dump(test_data, f)
            temp_file = f.name
        
        try:
            result = load_yaml_file(temp_file)
            assert result == test_data
        finally:
            os.unlink(temp_file)

    def test_load_yaml_file_not_found(self):
        """Test loading a non-existent YAML file."""
        with pytest.raises(FileNotFoundError):
            load_yaml_file("non_existent_file.yml")

    def test_load_invalid_yaml_file(self):
        """Test loading an invalid YAML file."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.yml', delete=False) as f:
            f.write("invalid: yaml\n\t bad_indentation: and tabs")
            temp_file = f.name
        
        try:
            with pytest.raises(yaml.YAMLError):
                load_yaml_file(temp_file)
        finally:
            os.unlink(temp_file)


class TestGetActionsFromFile:
    """Test cases for get_actions_from_file function."""

    def test_get_actions_from_simple_workflow(self):
        """Test extracting actions from a simple workflow."""
        workflow_content = """
name: Test Workflow
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
"""
        
        with patch('builtins.print'):  # Suppress print output during tests
            actions = get_actions_from_file(workflow_content, "test.yml")
        
        expected = [
            {"actionLink": "actions/checkout", "actionVersion": "v4", "workflowFileName": "test.yml"},
            {"actionLink": "actions/setup-python", "actionVersion": "v5", "workflowFileName": "test.yml"}
        ]
        
        assert actions == expected

    def test_get_actions_from_workflow_with_multiple_jobs(self):
        """Test extracting actions from workflow with multiple jobs."""
        workflow_content = """
name: Multi Job Workflow
on: [push]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-node@v4
      - uses: github/super-linter@v7
"""
        
        with patch('builtins.print'):
            actions = get_actions_from_file(workflow_content, "multi.yml")
        
        expected = [
            {"actionLink": "actions/checkout", "actionVersion": "v4", "workflowFileName": "multi.yml"},
            {"actionLink": "actions/setup-node", "actionVersion": "v4", "workflowFileName": "multi.yml"},
            {"actionLink": "github/super-linter", "actionVersion": "v7", "workflowFileName": "multi.yml"}
        ]
        
        assert actions == expected

    def test_get_actions_from_workflow_with_subpaths(self):
        """Test extracting actions with subpaths like github/codeql-action/init."""
        workflow_content = """
name: CodeQL Workflow
on: [push]
jobs:
  analyze:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
      - uses: github/codeql-action/analyze@v3
"""
        
        with patch('builtins.print'):
            actions = get_actions_from_file(workflow_content, "codeql.yml")
        
        expected = [
            {"actionLink": "actions/checkout", "actionVersion": "v4", "workflowFileName": "codeql.yml"},
            {"actionLink": "github/codeql-action/init", "actionVersion": "v3", "workflowFileName": "codeql.yml"},
            {"actionLink": "github/codeql-action/analyze", "actionVersion": "v3", "workflowFileName": "codeql.yml"}
        ]
        
        assert actions == expected

    def test_get_actions_from_workflow_no_jobs(self):
        """Test workflow with no jobs section."""
        workflow_content = """
name: No Jobs Workflow
on: [push]
"""
        
        with patch('builtins.print'):
            actions = get_actions_from_file(workflow_content, "empty.yml")
        
        assert actions == []

    def test_get_actions_from_workflow_job_no_steps(self):
        """Test workflow with job but no steps."""
        workflow_content = """
name: No Steps Workflow
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
"""
        
        with patch('builtins.print'):
            actions = get_actions_from_file(workflow_content, "nosteps.yml")
        
        assert actions == []

    def test_get_actions_from_workflow_steps_no_uses(self):
        """Test workflow with steps but no 'uses' directives."""
        workflow_content = """
name: No Uses Workflow
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - name: Run command
        run: echo "Hello world"
      - name: Another command
        run: ls -la
"""
        
        with patch('builtins.print'):
            actions = get_actions_from_file(workflow_content, "nouses.yml")
        
        assert actions == []

    def test_get_actions_invalid_uses_format(self):
        """Test workflow with invalid uses format (no @ separator)."""
        workflow_content = """
name: Invalid Uses Format
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout  # Missing @version
      - uses: actions/setup-python@v5  # Valid format
"""
        
        with patch('builtins.print'):
            actions = get_actions_from_file(workflow_content, "invalid.yml")
        
        # Should only capture the valid one
        expected = [
            {"actionLink": "actions/setup-python", "actionVersion": "v5", "workflowFileName": "invalid.yml"}
        ]
        
        assert actions == expected


class TestGetAllUsedActions:
    """Test cases for get_all_used_actions function."""

    def test_get_all_used_actions_with_workflows(self):
        """Test getting all actions from a directory with workflow files."""
        with tempfile.TemporaryDirectory() as temp_dir:
            workflows_dir = Path(temp_dir) / ".github" / "workflows"
            workflows_dir.mkdir(parents=True)
            
            # Create test workflow files
            workflow1 = workflows_dir / "test1.yml"
            workflow1.write_text("""
name: Test 1
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
""")
            
            workflow2 = workflows_dir / "test2.yml"
            workflow2.write_text("""
name: Test 2
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: github/super-linter@v7
""")
            
            with patch('builtins.print'):
                actions = get_all_used_actions(Path(temp_dir))
            
            expected = [
                {"actionLink": "actions/checkout", "actionVersion": "v4", "workflowFileName": "test1.yml"},
                {"actionLink": "github/super-linter", "actionVersion": "v7", "workflowFileName": "test2.yml"}
            ]
            
            # Sort both lists to compare regardless of order
            actions_sorted = sorted(actions, key=lambda x: x['actionLink'])
            expected_sorted = sorted(expected, key=lambda x: x['actionLink'])
            
            assert actions_sorted == expected_sorted

    def test_get_all_used_actions_testing_repo_fallback(self):
        """Test fallback to testing-repo directory when .github/workflows doesn't exist."""
        with tempfile.TemporaryDirectory() as temp_dir:
            testing_workflows_dir = Path(temp_dir) / "testing-repo" / ".github" / "workflows"
            testing_workflows_dir.mkdir(parents=True)
            
            workflow = testing_workflows_dir / "test.yml"
            workflow.write_text("""
name: Test
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/setup-node@v4
""")
            
            with patch('builtins.print'):
                actions = get_all_used_actions(Path(temp_dir))
            
            expected = [
                {"actionLink": "actions/setup-node", "actionVersion": "v4", "workflowFileName": "test.yml"}
            ]
            
            assert actions == expected

    def test_get_all_used_actions_no_workflows_found(self):
        """Test when no workflow files are found."""
        with tempfile.TemporaryDirectory() as temp_dir:
            with patch('builtins.print'):
                actions = get_all_used_actions(Path(temp_dir))
            
            assert actions == []

    def test_get_all_used_actions_with_malformed_yaml(self):
        """Test handling of malformed YAML files."""
        with tempfile.TemporaryDirectory() as temp_dir:
            workflows_dir = Path(temp_dir) / ".github" / "workflows"
            workflows_dir.mkdir(parents=True)
            
            # Create a valid workflow file
            valid_workflow = workflows_dir / "valid.yml"
            valid_workflow.write_text("""
name: Valid
on: [push]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
""")
            
            # Create a malformed workflow file
            invalid_workflow = workflows_dir / "invalid.yml"
            invalid_workflow.write_text("invalid:\nyaml:\n  - content\n    bad_indentation")
            
            with patch('builtins.print'):
                actions = get_all_used_actions(Path(temp_dir))
            
            # Should only return actions from valid file
            expected = [
                {"actionLink": "actions/checkout", "actionVersion": "v4", "workflowFileName": "valid.yml"}
            ]
            
            assert actions == expected


class TestInvokeValidateActions:
    """Test cases for invoke_validate_actions function."""

    def setup_method(self):
        """Set up test data for validation tests."""
        self.approved_actions = [
            {
                "actionLink": "actions/checkout",
                "versions": [
                    {
                        "version": "v4",
                        "deprecated": False
                    }
                ]
            },
            {
                "actionLink": "actions/setup-python",
                "versions": [
                    {
                        "version": "v5",
                        "deprecated": True
                    }
                ]
            },
            {
                "actionLink": "some/custom-action",
                "versions": [
                    {
                        "version": "v1",
                        "deprecated": False
                    }
                ]
            }
        ]

    def test_all_actions_approved(self):
        """Test when all actions are explicitly approved."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(self.approved_actions, f)
            approved_file = f.name
        
        actions_config = [
            {"actionLink": "actions/checkout", "actionVersion": "v4"},
            {"actionLink": "some/custom-action", "actionVersion": "v1"}
        ]
        
        try:
            with patch('builtins.print'):
                result = invoke_validate_actions(approved_file, actions_config)
            
            assert result is False  # No denied actions
        finally:
            os.unlink(approved_file)

    def test_some_actions_denied(self):
        """Test when some actions are not approved."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(self.approved_actions, f)
            approved_file = f.name
        
        actions_config = [
            {"actionLink": "actions/checkout", "actionVersion": "v4"},  # Approved
            {"actionLink": "unknown/action", "actionVersion": "v1"},     # Not approved
            {"actionLink": "another/unknown", "actionVersion": "v2"}     # Not approved
        ]
        
        try:
            with patch('builtins.print'):
                result = invoke_validate_actions(approved_file, actions_config)
            
            assert result is True  # Has denied actions
        finally:
            os.unlink(approved_file)

    def test_deprecated_actions_warning(self):
        """Test when deprecated actions are used."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(self.approved_actions, f)
            approved_file = f.name
        
        actions_config = [
            {"actionLink": "actions/setup-python", "actionVersion": "v5"}  # Deprecated
        ]
        
        try:
            with patch('builtins.print'):
                result = invoke_validate_actions(approved_file, actions_config)
            
            assert result is False  # Not denied, just deprecated
        finally:
            os.unlink(approved_file)

    def test_auto_approve_github_actions(self):
        """Test auto-approval of github/* actions."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump([], f)  # Empty approved list
            approved_file = f.name
        
        actions_config = [
            {"actionLink": "github/super-linter", "actionVersion": "v7"},
            {"actionLink": "github/codeql-action/init", "actionVersion": "v3"},
            {"actionLink": "github/some-unknown-action", "actionVersion": "v1"}
        ]
        
        try:
            with patch('builtins.print'):
                result = invoke_validate_actions(approved_file, actions_config)
            
            assert result is False  # All auto-approved
        finally:
            os.unlink(approved_file)

    def test_auto_approve_actions_namespace(self):
        """Test auto-approval of actions/* actions."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump([], f)  # Empty approved list
            approved_file = f.name
        
        actions_config = [
            {"actionLink": "actions/checkout", "actionVersion": "v4"},
            {"actionLink": "actions/setup-python", "actionVersion": "v5"},
            {"actionLink": "actions/cache/restore", "actionVersion": "v4"}
        ]
        
        try:
            with patch('builtins.print'):
                result = invoke_validate_actions(approved_file, actions_config)
            
            assert result is False  # All auto-approved
        finally:
            os.unlink(approved_file)

    def test_mixed_auto_approved_and_regular_actions(self):
        """Test mix of auto-approved and regular actions."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(self.approved_actions, f)
            approved_file = f.name
        
        actions_config = [
            {"actionLink": "github/super-linter", "actionVersion": "v7"},      # Auto-approved
            {"actionLink": "actions/checkout", "actionVersion": "v4"},        # Auto-approved
            {"actionLink": "some/custom-action", "actionVersion": "v1"},      # Explicitly approved
            {"actionLink": "unknown/action", "actionVersion": "v1"}           # Not approved
        ]
        
        try:
            with patch('builtins.print'):
                result = invoke_validate_actions(approved_file, actions_config)
            
            assert result is True  # Has one denied action
        finally:
            os.unlink(approved_file)

    def test_case_sensitivity_auto_approval(self):
        """Test that auto-approval is case-sensitive."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump([], f)  # Empty approved list
            approved_file = f.name
        
        actions_config = [
            {"actionLink": "github/super-linter", "actionVersion": "v7"},     # Should be auto-approved
            {"actionLink": "GitHub/super-linter", "actionVersion": "v7"},     # Should NOT be auto-approved (capital G)
            {"actionLink": "actions/checkout", "actionVersion": "v4"},        # Should be auto-approved
            {"actionLink": "Actions/checkout", "actionVersion": "v4"}         # Should NOT be auto-approved (capital A)
        ]
        
        try:
            with patch('builtins.print'):
                result = invoke_validate_actions(approved_file, actions_config)
            
            assert result is True  # Has denied actions (the capitalized ones)
        finally:
            os.unlink(approved_file)

    def test_auto_approval_debug_messages(self):
        """Test that auto-approval generates correct debug messages."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump([], f)
            approved_file = f.name
        
        actions_config = [
            {"actionLink": "github/super-linter", "actionVersion": "v7"},
            {"actionLink": "actions/checkout", "actionVersion": "v4"}
        ]
        
        try:
            with patch('builtins.print') as mock_print:
                invoke_validate_actions(approved_file, actions_config)
                
                # Check that debug messages were printed
                print_calls = [call.args[0] for call in mock_print.call_args_list]
                
                # Check for auto-approval messages
                github_debug = any("Auto-approving github action: github/super-linter" in call for call in print_calls)
                actions_debug = any("Auto-approving actions action: actions/checkout" in call for call in print_calls)
                
                assert github_debug, "Should print debug message for github action"
                assert actions_debug, "Should print debug message for actions action"
        finally:
            os.unlink(approved_file)

    def test_wrong_version_not_auto_approved(self):
        """Test that wrong version of approved action is still denied."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(self.approved_actions, f)
            approved_file = f.name
        
        actions_config = [
            {"actionLink": "some/custom-action", "actionVersion": "v2"}  # Approved v1, using v2
        ]
        
        try:
            with patch('builtins.print'):
                result = invoke_validate_actions(approved_file, actions_config)
            
            assert result is True  # Denied due to wrong version
        finally:
            os.unlink(approved_file)

    def test_empty_actions_config(self):
        """Test with empty actions configuration."""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
            json.dump(self.approved_actions, f)
            approved_file = f.name
        
        actions_config = []
        
        try:
            with patch('builtins.print'):
                result = invoke_validate_actions(approved_file, actions_config)
            
            assert result is False  # No actions to deny
        finally:
            os.unlink(approved_file)
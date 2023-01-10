import Console from 'winston/lib/winston/transports/console.js';
import { LEVEL, MESSAGE } from 'triple-beam';

class GitHubTransport extends Console {
  constructor(options = {}) {
    super(options);

    // Expose the name of this Transport on the prototype
    this.name = options.name || 'GitHub';
  }

  log(info, callback) {
    switch (info[LEVEL]) {
      case 'error':
        // eslint-disable-next-line no-param-reassign
        info[MESSAGE] = `::error::${info[MESSAGE]}`;
        break;
      case 'warn':
        // eslint-disable-next-line no-param-reassign
        info[MESSAGE] = `::warning::${info[MESSAGE]}`;
        break;
      case 'info':
        // eslint-disable-next-line no-param-reassign
        info[MESSAGE] = `::notice::${info[MESSAGE]}`;
        break;
      case 'debug':
        // eslint-disable-next-line no-param-reassign
        info[MESSAGE] = `::debug::${info[MESSAGE]}`;
        break;
      default:
        // take no action
        break;
    }

    super.log(info, callback);
  }
}

export default GitHubTransport;

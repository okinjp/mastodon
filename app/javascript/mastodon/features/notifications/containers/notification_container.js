import { connect } from 'react-redux';

import { mentionCompose } from '../../../actions/compose';
import {
  reblog,
  favourite,
  unreblog,
  unfavourite,
  emojiReact,
} from '../../../actions/interactions';
import { openModal } from '../../../actions/modal';
import {
  hideStatus,
  revealStatus,
} from '../../../actions/statuses';
import { boostModal } from '../../../initial_state';
import { makeGetNotification, makeGetStatus, makeGetReport } from '../../../selectors';
import Notification from '../components/notification';

const makeMapStateToProps = () => {
  const getNotification = makeGetNotification();
  const getStatus = makeGetStatus();
  const getReport = makeGetReport();

  const mapStateToProps = (state, props) => {
    const notification = getNotification(state, props.notification, props.accountId);
    return {
      notification: notification,
      status: notification.get('status') ? getStatus(state, { id: notification.get('status'), contextType: 'notifications' }) : null,
      report: notification.get('report') ? getReport(state, notification.get('report'), notification.getIn(['report', 'target_account', 'id'])) : null,
    };
  };

  return mapStateToProps;
};

const mapDispatchToProps = dispatch => ({
  onMention: (account, router) => {
    dispatch(mentionCompose(account, router));
  },

  onModalReblog (status, privacy) {
    dispatch(reblog(status, privacy));
  },

  onReblog (status, e) {
    if (status.get('reblogged')) {
      dispatch(unreblog(status));
    } else {
      if (e.shiftKey || !boostModal) {
        this.onModalReblog(status);
      } else {
        dispatch(openModal({ modalType: 'BOOST', modalProps: { status, onReblog: this.onModalReblog } }));
      }
    }
  },

  onReblogForceModal (status) {
    if (status.get('reblogged')) {
      dispatch(unreblog(status));
    } else {
      dispatch(openModal({ modalType: 'BOOST', modalProps: { status, onReblog: this.onModalReblog } }));
    }
  },

  onFavourite (status) {
    if (status.get('favourited')) {
      dispatch(unfavourite(status));
    } else {
      dispatch(favourite(status));
    }
  },

  onEmojiReact (status, emoji) {
    dispatch(emojiReact(status, emoji));
  },

  onToggleHidden (status) {
    if (status.get('hidden')) {
      dispatch(revealStatus(status.get('id')));
    } else {
      dispatch(hideStatus(status.get('id')));
    }
  },
});

export default connect(makeMapStateToProps, mapDispatchToProps)(Notification);

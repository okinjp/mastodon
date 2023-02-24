import React from 'react';
import ImmutablePropTypes from 'react-immutable-proptypes';
import PropTypes from 'prop-types';
import { FormattedMessage, injectIntl } from 'react-intl';
import emojify from '../features/emoji/emoji';
import classNames from 'classnames';

class EmojiReactionButton extends React.PureComponent {

  static propTypes = {
    name: ImmutablePropTypes.map,
    url: PropTypes.string,
    staticUrl: PropTypes.string,
    count: PropTypes.number.isRequired,
    me: PropTypes.bool,
    onClick: PropTypes.func,
  };

  render () {
    const { name, url, staticUrl, count, me } = this.props;

    let emojiHtml = null;
    if (url) {
      let customEmojis = {};
      customEmojis[name] = { url, static_url: staticUrl };
      emojiHtml = emojify(`:${name}:`, customEmojis);
    } else {
      emojiHtml = emojify(name);
    }

    const classList = {
      'emoji-reactions-bar__button': true,
      'toggled': me,
    };

    return (
      <button className={classNames(classList)} type='button'>
        <span className='emoji' dangerouslySetInnerHTML={{ __html: emojiHtml }} />
        <span className='count'>{count}</span>
      </button>
    );
  }

}

export default @injectIntl
class StatusEmojiReactionsBar extends React.PureComponent {

  static propTypes = {
    emojiReactions: ImmutablePropTypes.map.isRequired,
    statusId: PropTypes.string,
  };

  render () {
    const { emojiReactions, statusId } = this.props;

    const emojiButtons = React.Children.map(emojiReactions, (emoji) => (
      <EmojiReactionButton
        key={emoji.get('id')}
        name={emoji.get('name')}
        count={emoji.get('count')}
        me={emoji.get('me')}
        url={emoji.get('url')}
        staticUrl={emoji.get('static_url')}
      />));

    return (
      <div className='status__emoji-reactions-bar'>
        {emojiButtons}
      </div>
    );
  }

}

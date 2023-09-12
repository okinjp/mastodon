# frozen_string_literal: true

class EmojiReactionValidator < ActiveModel::Validator
  SUPPORTED_EMOJIS = Oj.load_file(Rails.root.join('app', 'javascript', 'mastodon', 'features', 'emoji', 'emoji_map.json').to_s).keys.freeze

  def validate(emoji_reaction)
    return if emoji_reaction.name.blank?

    emoji_reaction.errors.add(:name, I18n.t('reactions.errors.unrecognized_emoji')) if emoji_reaction.custom_emoji_id.blank? && !unicode_emoji?(emoji_reaction.name)
    emoji_reaction.errors.add(:name, I18n.t('reactions.errors.unrecognized_emoji')) if emoji_reaction.custom_emoji_id.present? && disabled_custom_emoji?(emoji_reaction.custom_emoji)
    emoji_reaction.errors.add(:name, I18n.t('reactions.errors.banned')) if deny_emoji_reactions?(emoji_reaction)
  end

  private

  def unicode_emoji?(name)
    SUPPORTED_EMOJIS.include?(name)
  end

  def disabled_custom_emoji?(custom_emoji)
    custom_emoji.nil? ? false : custom_emoji.disabled
  end

  def deny_emoji_reactions?(emoji_reaction)
    return false unless Setting.enable_block_emoji_reaction_settings
    return false if emoji_reaction.status.account.user.nil?
    return false if emoji_reaction.status.account_id == emoji_reaction.account_id

    deny_from_all?(emoji_reaction) || non_follower?(emoji_reaction) || non_following?(emoji_reaction)
  end

  def deny_from_all?(emoji_reaction)
    emoji_reaction.status.account.emoji_reactions_deny_from_all?
  end

  def non_following?(emoji_reaction)
    emoji_reaction.status.account.emoji_reactions_must_following? && !emoji_reaction.status.account.following?(emoji_reaction.account)
  end

  def non_follower?(emoji_reaction)
    emoji_reaction.status.account.emoji_reactions_must_follower? && !emoji_reaction.account.following?(emoji_reaction.status.account)
  end
end

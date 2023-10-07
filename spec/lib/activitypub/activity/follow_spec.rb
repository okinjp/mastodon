# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ActivityPub::Activity::Follow do
  let(:actor_type) { 'Person' }
  let(:note)       { '' }
  let(:sender)    { Fabricate(:account, domain: 'example.com', inbox_url: 'https://example.com/inbox', actor_type: actor_type, note: note) }
  let(:recipient) { Fabricate(:account) }

  let(:json) do
    {
      '@context': 'https://www.w3.org/ns/activitystreams',
      id: 'foo',
      type: 'Follow',
      actor: ActivityPub::TagManager.instance.uri_for(sender),
      object: ActivityPub::TagManager.instance.uri_for(recipient),
    }.with_indifferent_access
  end

  describe '#perform' do
    subject { described_class.new(json, sender) }

    context 'with no prior follow' do
      context 'with an unlocked account' do
        before do
          subject.perform
        end

        it 'creates a follow from sender to recipient' do
          expect(sender.following?(recipient)).to be true
          expect(sender.active_relationships.find_by(target_account: recipient).uri).to eq 'foo'
        end

        it 'does not create a follow request' do
          expect(sender.requested?(recipient)).to be false
        end
      end

      context 'when silenced account following an unlocked account' do
        before do
          sender.touch(:silenced_at)
          subject.perform
        end

        it 'does not create a follow from sender to recipient' do
          expect(sender.following?(recipient)).to be false
        end

        it 'creates a follow request' do
          expect(sender.requested?(recipient)).to be true
          expect(sender.follow_requests.find_by(target_account: recipient).uri).to eq 'foo'
        end
      end

      context 'with an unlocked account muting the sender' do
        before do
          recipient.mute!(sender)
          subject.perform
        end

        it 'creates a follow from sender to recipient' do
          expect(sender.following?(recipient)).to be true
          expect(sender.active_relationships.find_by(target_account: recipient).uri).to eq 'foo'
        end

        it 'does not create a follow request' do
          expect(sender.requested?(recipient)).to be false
        end
      end

      context 'when locked account' do
        before do
          recipient.update(locked: true)
          subject.perform
        end

        it 'does not create a follow from sender to recipient' do
          expect(sender.following?(recipient)).to be false
        end

        it 'creates a follow request' do
          expect(sender.requested?(recipient)).to be true
          expect(sender.follow_requests.find_by(target_account: recipient).uri).to eq 'foo'
        end
      end

      context 'when unlocked account but locked from bot' do
        let(:actor_type) { 'Service' }

        before do
          recipient.user.settings['lock_follow_from_bot'] = true
          recipient.user.save!
          subject.perform
        end

        it 'does not create a follow from sender to recipient' do
          expect(sender.following?(recipient)).to be false
        end

        it 'creates a follow request' do
          expect(sender.requested?(recipient)).to be true
          expect(sender.follow_requests.find_by(target_account: recipient).uri).to eq 'foo'
        end
      end

      context 'when unlocked misskey proxy account but locked from bot' do
        let(:note) { 'i am proxy.' }

        before do
          Fabricate(:instance_info, domain: 'example.com', software: 'misskey')
          recipient.user.settings['lock_follow_from_bot'] = true
          recipient.user.save!
          subject.perform
        end

        it 'does not create a follow from sender to recipient' do
          expect(sender.following?(recipient)).to be false
        end

        it 'creates a follow request' do
          expect(sender.requested?(recipient)).to be true
          expect(sender.follow_requests.find_by(target_account: recipient).uri).to eq 'foo'
        end
      end

      context 'when unlocked mastodon proxy account but locked from bot' do
        let(:note) { 'i am proxy.' }

        before do
          Fabricate(:instance_info, domain: 'example.com', software: 'mastodon')
          recipient.user.settings['lock_follow_from_bot'] = true
          recipient.user.save!
          subject.perform
        end

        it 'does not create a follow from sender to recipient' do
          expect(sender.following?(recipient)).to be true
        end
      end

      context 'when unlocked misskey normal account but locked from bot' do
        before do
          Fabricate(:instance_info, domain: 'example.com', software: 'misskey')
          recipient.user.settings['lock_follow_from_bot'] = true
          recipient.user.save!
          subject.perform
        end

        it 'does not create a follow from sender to recipient' do
          expect(sender.following?(recipient)).to be true
        end
      end

      context 'when domain block reject_straight_follow' do
        before do
          Fabricate(:domain_block, domain: 'example.com', reject_straight_follow: true)
          subject.perform
        end

        it 'does not create a follow from sender to recipient' do
          expect(sender.following?(recipient)).to be false
        end

        it 'creates a follow request' do
          expect(sender.requested?(recipient)).to be true
          expect(sender.follow_requests.find_by(target_account: recipient).uri).to eq 'foo'
        end
      end

      context 'when domain block reject_new_follow' do
        before do
          Fabricate(:domain_block, domain: 'example.com', reject_new_follow: true)
          stub_request(:post, 'https://example.com/inbox').to_return(status: 200, body: '', headers: {})
          subject.perform
        end

        it 'does not create a follow from sender to recipient' do
          expect(sender.following?(recipient)).to be false
          expect(sender.requested?(recipient)).to be false
        end
      end
    end

    context 'when a follow relationship already exists' do
      before do
        sender.active_relationships.create!(target_account: recipient, uri: 'bar')
      end

      context 'with an unlocked account' do
        before do
          subject.perform
        end

        it 'correctly sets the new URI' do
          expect(sender.active_relationships.find_by(target_account: recipient).uri).to eq 'foo'
        end

        it 'does not create a follow request' do
          expect(sender.requested?(recipient)).to be false
        end
      end

      context 'when silenced account following an unlocked account' do
        before do
          sender.touch(:silenced_at)
          subject.perform
        end

        it 'correctly sets the new URI' do
          expect(sender.active_relationships.find_by(target_account: recipient).uri).to eq 'foo'
        end

        it 'does not create a follow request' do
          expect(sender.requested?(recipient)).to be false
        end
      end

      context 'with an unlocked account muting the sender' do
        before do
          recipient.mute!(sender)
          subject.perform
        end

        it 'correctly sets the new URI' do
          expect(sender.active_relationships.find_by(target_account: recipient).uri).to eq 'foo'
        end

        it 'does not create a follow request' do
          expect(sender.requested?(recipient)).to be false
        end
      end

      context 'when locked account' do
        before do
          recipient.update(locked: true)
          subject.perform
        end

        it 'correctly sets the new URI' do
          expect(sender.active_relationships.find_by(target_account: recipient).uri).to eq 'foo'
        end

        it 'does not create a follow request' do
          expect(sender.requested?(recipient)).to be false
        end
      end
    end

    context 'when a follow request already exists' do
      before do
        sender.follow_requests.create!(target_account: recipient, uri: 'bar')
      end

      context 'when silenced account following an unlocked account' do
        before do
          sender.touch(:silenced_at)
          subject.perform
        end

        it 'does not create a follow from sender to recipient' do
          expect(sender.following?(recipient)).to be false
        end

        it 'correctly sets the new URI' do
          expect(sender.requested?(recipient)).to be true
          expect(sender.follow_requests.find_by(target_account: recipient).uri).to eq 'foo'
        end
      end

      context 'when locked account' do
        before do
          recipient.update(locked: true)
          subject.perform
        end

        it 'does not create a follow from sender to recipient' do
          expect(sender.following?(recipient)).to be false
        end

        it 'correctly sets the new URI' do
          expect(sender.requested?(recipient)).to be true
          expect(sender.follow_requests.find_by(target_account: recipient).uri).to eq 'foo'
        end
      end
    end
  end
end

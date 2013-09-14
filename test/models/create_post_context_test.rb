require 'test_helper'

class CreatePostContextTest < ActiveSupport::TestCase
  subject { CreatePostContext }
  let(:attributes) { %w(user post_text tag_factory popular_index object_store) }

  include AttributesTest

  class UserRoleTest < ActiveSupport::TestCase
    subject { CreatePostContext::UserRole }

    include DelegatorTest

    it 'creates a post' do
      user = OpenStruct.new username: 'foo'
      role = subject.new(user)
      test = role.new_post 'this is a post'
      test.message.must_equal 'this is a post'
      test.username.must_equal 'foo'
      test.post_time.to_i.must_be_close_to DateTime.now.to_i, 1
      test.post_id.wont_be_nil
    end
  end

  class TagFactoryRoleTest < ActiveSupport::TestCase
    subject { CreatePostContext::TagFactoryRole }

    include DelegatorTest
  end

  class TagRoleTest < ActiveSupport::TestCase
    subject { CreatePostContext::TagRole }

    include DelegatorTest

    it 'adds post according to time hack' do
      post = OpenStruct.new time_hack: 4, post_id: 1
      tag = {}
      role = subject.new(tag)
      role.add_post(post)
      tag[1].must_equal post.time_hack
    end
  end

  class PopularIndexRoleTest < ActiveSupport::TestCase
    subject { CreatePostContext::PopularIndexRole }

    include DelegatorTest

    it 'adds post according to score hack' do
      post = OpenStruct.new score_hack: 4, post_id: 1
      tag = {}
      role = subject.new(tag)
      role.add_post(post)
      tag[1].must_equal post.score_hack
    end
  end

  class PostRoleTest < ActiveSupport::TestCase
    subject { CreatePostContext::PostRole }

    include DelegatorTest

    it 'time_hack is based on the post_time' do
      post = OpenStruct.new post_time: DateTime.now
      role = subject.new(post)
      role.time_hack.must_equal post.post_time.to_i
    end

    it 'score_hack is based on the post_time' do
      post = OpenStruct.new post_time: DateTime.now
      role = subject.new(post)
      role.score_hack.must_equal post.post_time.to_i
    end

    it 'includes the post username in the tags' do
      post = OpenStruct.new username: 'foo', message: ''
      role = subject.new(post)
      role.tags.must_include '@foo'
    end

    it 'includes @usernames included in the message' do
      post = OpenStruct.new username: 'foo', message: 'foo @bar baz'
      role = subject.new(post)
      role.tags.must_include '@bar'
    end

    it 'includes #tags included in the message' do
      post = OpenStruct.new username: 'foo', message: 'foo #bar baz'
      role = subject.new(post)
      role.tags.must_include '#bar'
    end

    it 'lowercases tags' do
      post = OpenStruct.new username: 'foo', message: 'foo #BAR baz'
      role = subject.new(post)
      role.tags.must_include '#bar'
      role.tags.wont_include '#BAR'
    end

    it 'lowercases usernames' do
      post = OpenStruct.new username: 'foo', message: 'foo @BAR baz'
      role = subject.new(post)
      role.tags.must_include '@bar'
      role.tags.wont_include '@BAR'
    end

    it 'rejects duplicates' do
      post = OpenStruct.new username: 'foo', message: 'foo #bar #bar baz'
      role = subject.new(post)
      role.tags.uniq.count.must_equal role.tags.count
    end

    it 'rejects tags shorter than two characters' do
      post = OpenStruct.new username: 'foo', message: 'foo #b baz'
      role = subject.new(post)
      role.tags.wont_include '#b'
    end
  end

end

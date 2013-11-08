require_relative '../test_helper'

class RedisHashObjectStoreTest < BaseTestCase
  subject { RedisHashObjectStore }

  it 'can store and get objects' do
    model = ObjectStoreTestModel.new foo: 'one', bar: 'two', baz: 'three'
    hash = redis.hash 'HashObjectStoreTest'
    object_store = subject.new hash, ObjectStoreTestModel
    object_store.save model, 1
    test = object_store.get 1
    test.must_be_instance_of ObjectStoreTestModel
    test.foo.must_equal 'one'
    test.bar.must_equal 'two'
    test.baz.must_equal 'three'
  end

  it 'can get a list of objects' do
    model = ObjectStoreTestModel.new foo: 'one', bar: 'two', baz: 'three'
    hash = redis.hash 'HashObjectStoreTest'
    object_store = subject.new hash, ObjectStoreTestModel
    object_store.save model, 1
    object_store.save model, 2
    test = object_store.get [1, 2]
    test.must_be_instance_of Array
    test.count.must_equal 2
  end

  it 'returns nil if the object does not exist' do
    hash = redis.hash 'HashObjectStoreTest'
    object_store = subject.new hash, ObjectStoreTestModel
    test = object_store.get 'thing that does not exist'
    test.must_be_nil
  end

  it 'returns empty array if an empty array passed in' do
    hash = redis.hash 'HashObjectStoreTest'
    object_store = subject.new hash, ObjectStoreTestModel
    test = object_store.get []
    test.must_be_empty
  end

  it 'returns nil if nil passed in' do
    hash = redis.hash 'HashObjectStoreTest'
    object_store = subject.new hash, ObjectStoreTestModel
    test = object_store.get nil
    test.must_be_nil
  end

  it 'removes missing objects from return array' do
    model = ObjectStoreTestModel.new foo: 'one', bar: 'two', baz: 'three'
    hash = redis.hash 'HashObjectStoreTest'
    object_store = subject.new hash, ObjectStoreTestModel
    object_store.save model, 1
    object_store.save model, 2
    test = object_store.get [1, 2, 3]
    test.must_be_instance_of Array
    test.count.must_equal 2
  end

  it 'can delete objects' do
    model = ObjectStoreTestModel.new foo: 'one', bar: 'two', baz: 'three'
    hash = redis.hash 'HashObjectStoreTest'
    object_store = subject.new hash, ObjectStoreTestModel
    object_store.save model, 1
    object_store.save model, 2
    test = object_store.get [1, 2]
    test.must_be_instance_of Array
    test.count.must_equal 2
    object_store.delete 1
    object_store.delete 2
    test = object_store.get [1, 2]
    test.must_be_instance_of Array
    test.count.must_equal 0
  end

end
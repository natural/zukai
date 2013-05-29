assert = require 'assert'
{createClient} = require 'riakpbc'
{createModel} = require '../src'


PrimaryModel = SecondaryModel = TertiaryModel = null


describe 'Links', ->
  before (done)->
    connection = createClient()

    PrimaryModel = createModel
      name: 'primary-link-test'
      connection: connection

    SecondaryModel = createModel
      name: 'secondary-link-test'
      connection: connection

    TertiaryModel = createModel
      name: 'tertiary-link-test'
      connection: connection

    done()

  describe 'objects with links', ->
    it 'should save and resolve one link', (done)->
      tag = 'relation-type'
      primary = PrimaryModel.create 'key-1', a:1, b:2
      primary.save (err, object)->
        assert not err
        assert object.key == primary.key

        secondary = SecondaryModel.create 'key-2', c:3, d:4
        secondary.relate tag, primary
        secondary.save (err, object)->
          assert not err
          assert object.key == secondary.key

          links = secondary.links
          assert links.length == 1
          link = links[0]
          assert link.tag == tag
          assert link.key == primary.key
          assert link.bucket == primary.bucket

          object.resolve tag, (err, docs)->
            assert not err
            assert docs
            assert docs.length == 1
            doc = docs[0]
            assert doc.key == primary.key
            assert doc.bucket == primary.bucket

            primary.del().then ->
              secondary.del().then done

    it 'should save and resolve multiple links', (done)->
      tag = 'multi-type'

      primary = PrimaryModel.create 'key-4', a:1, b:2
      primary.save (err, p)->
        assert not err
        assert p.key == primary.key

        secondary = SecondaryModel.create 'key-5', c:3, d:4
        secondary.save (err, q)->
          assert not err
          assert q.key == secondary.key

          tertiary = TertiaryModel.create 'key-6', e:5, f:6
          tertiary.relate tag, primary
          tertiary.relate tag, secondary

          tertiary.save (err, t)->
            assert t.key == tertiary.key

            TertiaryModel.get('key-6').then (t)->
              assert t.key == tertiary.key
              assert t.links.length == 2
              t.resolve tag, (err, docs)->
                assert not err
                assert docs.length == 2
                buckets = (doc.bucket for doc in docs)
                assert PrimaryModel.bucket in buckets
                assert SecondaryModel.bucket in buckets

                tertiary.del().then ->
                  secondary.del().then ->
                    primary.del().then done

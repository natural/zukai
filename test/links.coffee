assert = require 'assert'
{createClient} = require 'riakpbc'
{createModel} = require '../src'


PrimaryModel = SecondaryModel = TertiaryModel = null
primary = secondary = null


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


  describe 'link method', ->
    it 'should support getting a link by tag', (done)->
      tag = 'it'
      p = primary = PrimaryModel.create 'key-0', a:0, b:-1
      assert p.key
      s = secondary = SecondaryModel.create 'key-00'
      assert p.link tag, s

      link = primary.link 'it'
      assert link.key == secondary.key
      links = primary.link 'nope'
      assert links.length == 0
      done()

    it 'should support getting a link by tag and bucket', (done)->
      link = primary.link 'it', SecondaryModel.bucket
      assert link.key == secondary.key
      links = primary.link 'it', 'nope'
      assert links.length == 0
      links = primary.link 'nope', SecondaryModel.bucket
      assert links.length == 0
      done()

    it 'should support updating a link if it already exists', (done)->
      primary.links.splice 0, primary.links.length
      primary.link 't', bucket:'b', key:'k'
      link = primary.link 't'

      assert link.tag == 't'
      assert link.bucket == 'b'
      assert link.key == 'k'

      primary.link 't', bucket:'b', key:'J', update=true
      updated =  primary.link 't'
      assert link.tag == 't'
      assert link.bucket == 'b'
      assert link.key == 'J'

      assert primary.links.length == 1
      done()


  describe 'objects with links', ->
    it 'should save and resolve one link', (done)->
      tag = 'relation-type'
      primary = PrimaryModel.create 'key-1', a:1, b:2
      primary.put().then (object)->
        assert object.key == primary.key

        secondary = SecondaryModel.create 'key-2', c:3, d:4
        secondary.link tag, primary
        secondary.put().then (object)->
          assert object.key == secondary.key

          links = secondary.links
          assert links.length == 1
          link = links[0]
          assert link.tag == tag
          assert link.key == primary.key
          assert link.bucket == primary.bucket

          object.walk(tag).then (docs)->
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
      primary.put().then (p)->
        assert p.key == primary.key

        secondary = SecondaryModel.create 'key-5', c:3, d:4
        secondary.put().then (q)->
          assert q.key == secondary.key

          tertiary = TertiaryModel.create 'key-6', e:5, f:6
          tertiary.link tag, primary
          tertiary.link tag, secondary

          tertiary.put().then (t)->
            assert t.key == tertiary.key

            TertiaryModel.get('key-6').then (t)->
              assert t.key == tertiary.key
              assert t.links.length == 2
              t.walk(tag).then (docs)->
                assert docs.length == 2
                buckets = (doc.bucket for doc in docs)
                assert PrimaryModel.bucket in buckets
                assert SecondaryModel.bucket in buckets

                tertiary.del().then ->
                  secondary.del().then ->
                    primary.del().then done

    it 'should support walking via .get', (done)->
      tag = 'multi-type'

      primary = PrimaryModel.create 'key-10', a:1, b:2
      primary.put().then (p)->
        assert p.key == primary.key

        secondary = SecondaryModel.create 'key-11', c:3, d:4
        secondary.put().then (q)->
          assert q.key == secondary.key

          tertiary = TertiaryModel.create 'key-12', e:5, f:6
          tertiary.link tag, primary
          tertiary.link tag, secondary

          tertiary.put().then (t)->
            assert t.key == tertiary.key

            TertiaryModel.get('key-12', walk:'*').then (t)->
              assert t.length == 3
              tertiary.del().then ->
                secondary.del().then ->
                  primary.del().then done


    it 'should support walking via .walk', (done)->
      tag = 'multi-type'

      primary = PrimaryModel.create 'key-10', a:1, b:2
      primary.put().then (p)->
        assert p.key == primary.key

        secondary = SecondaryModel.create 'key-11', c:3, d:4
        secondary.put().then (q)->
          assert q.key == secondary.key

          tertiary = TertiaryModel.create 'key-12', e:5, f:6
          tertiary.link tag, primary
          tertiary.link tag, secondary

          tertiary.put().then (t)->
            assert t.key == tertiary.key

            t.walk '*', (err, docs)->
              assert not err
              assert docs.length == 2

              tertiary.del().then ->
                secondary.del().then ->
                  primary.del().then done

    it 'should support walking via .walk with options', (done)->
      tag = 'multi-bucket-and-tag-type'

      primary = PrimaryModel.create 'key-10', a:1, b:2
      primary.put().then (p)->
        assert p.key == primary.key

        secondary = SecondaryModel.create 'key-11', c:3, d:4
        secondary.put().then (q)->
          assert q.key == secondary.key

          tertiary = TertiaryModel.create 'key-12', e:5, f:6
          tertiary.link tag, primary
          tertiary.link tag, secondary

          tertiary.put().then (t)->
            assert t.key == tertiary.key

            t.walk tag:tag, (err, docs)->
              assert not err
              assert docs.length == 2

              t.walk bucket:primary.bucket, (err, docs)->
                assert not err
                assert docs.length == 1

                tertiary.del().then ->
                  secondary.del().then ->
                    primary.del().then done

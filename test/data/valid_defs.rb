td = TaipoTestHelper::TestData.new

td.add 'String',
       pass: ['This is a test.', ''],
       fail: [:foo, Object.new, nil]
td.add 'Array<String>',
       pass: [['foo'], ['foo', 'bar'], ['']],
       fail: [[], [1], [nil], '', Object.new, nil]
td.add 'Hash<Symbol,String>',
       pass: [{a: ''}, {a: 'foo', b: 'bar'}],
       fail: [{}, {a: 1}, {'a' => 'foo'}, {a: 'foo', b: 1}, {a: nil}, 
              Object.new, nil]
td.add 'Collection<Integer,String,Array<Integer>>',
       pass: [],
       fail: []
td.add 'String|Float',
       pass: ['foo', 1.0, '', 0.0],
       fail: [:foo, 1, 0, Object.new, nil]
td.add 'Array|Hash|Float',
       pass: [[1], {a: 1}, 1.0, [], {}, 0.0],
       fail: [1, Object.new, nil]
td.add 'Array|Symbol|Float|Regexp',
       pass: [],
       fail: [Object.new, nil]
td.add 'Array<Array<String>>',
       pass: [[['foo', 'bar'], ['foo', 'bar']], [['']]],
       fail: [['foo'], [[['foo']]], [['foo', :bar]], [['foo'], [nil]], 
              Object.new, nil]
td.add 'String|Array<Integer>',
       pass: ['foo', [1], '', [0]],
       fail: [:foo, 1, [1.0], Object.new, nil]
td.add 'Array<Integer>|String',
       pass: ['foo', [1], '', [0]],
       fail: [:foo, 1, [1.0], Object.new, nil]
td.add 'String|Integer|Array<Hash<Symbol,Object>>',
       pass: ['foo', 1, [{a: Object.new}], '', 0, [{a: ''}]],
       fail: [:foo, 1.0, {a: Object.new}, Object.new, nil]
td.add 'String|Array<String|Integer>|Regexp',
       pass: ['foo', ['foo'], [1], ['foo', 1], /woo/, '', [''], [0]],
       fail: [:foo, [:foo], [1.0], Object.new, nil]
td.add 'Boolean|Array<String|Hash<Symbol,Integer>|Array<String>>',
       pass: [true, false, ['foo', {a: 1}, ['foo']], [''], [{a: 0}], [['']]],
       fail: ['true', 'false', [:foo, [:a, 1], [:foo]], [Object.new],
              Object.new, nil]
td.add 'Array(len: 5)',
       pass: [Array.new(5)],
       fail: [Array.new(4), Array.new(6), 'AAAAAA', Object.new, nil]
td.add 'String(format: /woo/)',
       pass: ['woo', 'woot'],
       fail: ['w00', '', Object.new, nil]
td.add 'String(#size)',
       pass: ['foo', ''],
       fail: [Object.new, nil]
td.add 'String(#size, #to_s)',
       pass: ['foo', ''],
       fail: [Object.new, nil]
td.add 'Symbol(val: :foo)',
       pass: [:foo],
       fail: [:food, :bar, Object.new, nil]
td.add 'Integer(min: 1, max: 10)',
       pass: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10],
       fail: ['1', Object.new, nil]
td.add 'Array<String(min: 3)>',
       pass: [['foo'], ['foo', 'bar']],
       fail: [['fo', 'ba'], [], Object.new, nil]
td.add 'Hash<Symbol,String(min: 3)>',
       pass: [{a: 'foo'}, {a: 'foo', b: 'bar'}],
       fail: [[:foo, 'bar'], {a: 'fo'}, {}, Object.new, nil]
td.add 'Array<String(min: 3)>(max: 10)',
       pass: [['foo'], ['foo', 'barbar']],
       fail: [['fo'], ['000', '111', '222', '333', '444', '555', '666', '777',
              '888', '999', '---'], Object.new, nil]
td.add 'Hash<Symbol, String>',
       pass: [{a: 'foo'}, {a: 'foo', b: 'bar'}],
       fail: [{a: 3}, {a: 'foo', b: 3}, Object.new, nil]
td.add 'String(val: "This is a test.")',
       pass: ['This is a test.'],
       fail: ['foo', 'This is a test', Object.new, nil]
td.add '#to_s',
       pass: ['foo', :bar, 1, nil],
       fail: []
td.add '(#to_s, #to_i)',
       pass: ['foo', 1, nil],
       fail: [Object.new]
td.add '#to_s|#to_i',
       pass: ['foo', Object.new, nil],
       fail: []
td.add '(#to_s, #to_i)|#to_f',
       pass: ['foo',  nil],
       fail: [Object.new]
td.add 'Array<#to_s>',
       pass: [['foo', 1]],
       fail: ['foo', 1]
td.add 'Array<(#to_s, #to_i)>',
       pass: [['foo'], ['foo', 1, nil]],
       fail: ['foo', 1, [Object.new]]
td.add ':foo',
       pass: [:foo],
       fail: [:bar, 'foo', Object.new, nil]
td.add ':foo|:bar',
       pass: [:foo, :bar],
       fail: [:foobar, 'foo', 'bar', 1, Object.new, nil]
td.add 'Array<:foo>',
       pass: [[:foo], [:foo, :foo]],
       fail: [:foo, [:bar], 1, Object.new, nil]
td.add 'String?',
       pass: ['foo', 'foo bar', nil],
       fail: [:foo, 1, Object.new]
td.add 'String?|Integer?',
       pass: ['foo', 1, nil],
       fail: [:foo, 1.0, Object.new]
td.add 'Array<Integer?>',
       pass: [[1], [1, 2], [nil], [nil, 1]],
       fail: ['foo', ['foo'], [1, 'foo'], [], Object.new, nil]

td

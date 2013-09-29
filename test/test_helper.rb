require 'minitest/autorun'
require 'minitest/pride'
require 'mocha/setup'

require 'hyper_resource'

HAL_BODY = {
  'attr1' => 'val1',
  'attr2' => 'val2',
  '_links' => {
    'self' => {'href' => '/obj1/'},
    'foobars' => [
      { 'name' => 'foobar',
        'templated' => true,
        'href' => 'http://example.com/foobars/{foobar}'
      }
    ]
  },
  '_embedded' => {
    'obj1s' => [
      { 'attr3' => 'val3',
        'attr4' => 'val4',
        '_links' => {
          'self' => {'href' => '/obj1/1'},
          'next' => {'href' => '/obj1/2'}
        }
      },
      { 'attr3' => 'val5',
        'attr4' => 'val6',
        '_links' => {
          'self' => {'href' => '/obj1/2'},
          'previous' => {'href' => '/obj1/1'}
        }
      }
    ]
  }
}


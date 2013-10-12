require 'test_helper'

describe HyperResource do
  describe 'Utils' do
    describe 'class_attribute' do
      it 'inherits properly' do
        class A
          include HyperResource::Modules::Utils
          _hr_class_attribute :a
        end
        class B < A; end

        class_a_msg = A.a = "from class A"
        A.a.must_equal class_a_msg
        B.a.must_equal class_a_msg

        class_b_msg = B.a = "from class B"
        A.a.must_equal class_a_msg
        B.a.must_equal class_b_msg
      end
    end
  end
end

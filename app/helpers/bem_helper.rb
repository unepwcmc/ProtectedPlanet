module BemHelper
  def bem b_or_e, *modifiers
    modifiers.each_with_object(b_or_e.dup) { |m, final|
      final << " #{b_or_e}--#{m}"
    }
  end
end

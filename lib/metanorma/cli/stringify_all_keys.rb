class Array
  def stringify_all_keys
    map do |v|
      case v
      when Hash, Array
        v.stringify_all_keys
      else 
        v
      end
    end
  end
end

class Hash
  def stringify_all_keys
    result = {}
    each do |k, v|
      result[k.to_s] = case v
                       when Hash, Array
                         v.stringify_all_keys
                       else 
                         v
                       end
    end
    result
  end
end
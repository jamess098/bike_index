class SerialNormalizerError < StandardError
end


class SerialNormalizer
  def initialize(creation_params = {})
    @bike_id = creation_params[:bike_id]
    @serial = creation_params[:serial]
    @serial = @serial.strip if @serial.present?
    @bike = find_bike
  end

  def find_bike
    return nil unless @bike_id.present?
    begin
    return Bike.unscoped.find(@bike_id)
    rescue
      raise SerialNormalizerError, "Oh no! We couldn't find that bike"
    end
  end

  def normalized
    return @serial if @serial.downcase == "absent"
    normalized = @serial.upcase
    key_hash = {'O' => '0',
      '|IL' => '1',
      'S' => '5',
      'Z' => '2',
      'B' => '8'
    }
    key_hash.keys.each do |k|
      normalized.gsub!(/[#{k}]/, key_hash[k])
      normalized.gsub!(/[^\w]|[_]/, ' ') # turn all non letter/numbers into spaces
    end
    @serial = normalized.gsub(/\s+/,' ') # remove multiple spaces
    return @serial
  end

  def find_normalized
    if @serial == "absent"
      bikes = Bike.where(serial_number: "absent")
    else
      bikes = Bike.where("serial_normalized like ?", @serial)
    end
    return bikes
  end

  def search
    @serial = normalized
    bikes = find_normalized
    return bikes
  end

end
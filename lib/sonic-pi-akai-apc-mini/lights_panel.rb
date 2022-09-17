class SonicPiAkaiApcMini::LightsPanel
  def initialize(default:, &block)
    @current = Hash.new(default)
    @changes = {}
    @mutex = Mutex.new
    @block = block or raise StandardError, 'must provide a block'
  end

  def set(values = {})
    values.each do |k, v|
      self[k] = v
    end
    flush
  end

  def []=(k, v)
    @mutex.synchronize do
      if @current[k] == v
        @changes.delete(k)
      else
        @changes[k] = v
      end
    end
  end

  def [](k)
    @changes[k] || @current[k]
  end

  def flush
    @mutex.synchronize do
      @changes.each do |k, v|
        @block.call(k, v)
        @current[k] = v
      end
      @changes.clear
    end
  end
end

class PrettifyLogOutput

  def initialize
    @start = Time.now
  end

  def start
    'PROCESSING: ' + Time.now.to_s[0..18]
  end

  def new_line
    "\n"
  end

  def end
    'PROCESSED: ' + Time.now.to_s[0..18]
  end

  def run_time
    run_time = Time.now - @start
    'RUN TIME: ' + (run_time / 60).to_s[0..3] + ' mins'
  end

end

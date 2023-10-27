class PrintWorker
  include Sidekiq::Worker

  def perform(*args)
    # Do something later
    print "I did the job, I am a good worker"
  end
end
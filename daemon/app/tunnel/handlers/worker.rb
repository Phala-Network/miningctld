class TunnelSession
  def handle_worker_should_run(message)
    role_instance.run!(
      controller_uri: message.worker_should_run.account.secret_phrase,
      ws_url: message.worker_should_run.ws_url
    )
    nil
  end

  def handle_report_worker_info(message)
    if message.target === :WORKER
      $logger.info 'Controller has set this worker\'s mining intention!'
      (role_instance.intention_set = true) if message.report_worker_info.status === :INTENTION_SET
      return nil
    end

    if message.target === :CONTROLLER
      $logger.info "Daemon \##{@daemon.uuid}(#{@daemon.id}, #{@daemon.role}, #{@daemon.description}): Reported status #{message.report_worker_info.status}"
      @daemon.worker_states.update :status => message.report_worker_info.status

      unless message.report_worker_info.status === :IDLE || message.report_worker_info.status === :ERROR
        if message.report_worker_info.status === :WAITING
          @daemon.worker_states.set_intention

          return {
            report_worker_info: {
              status: :INTENTION_SET
            }
          }
        end

        return nil
      end

      {
        worker_should_run: {
          account: @daemon.account.to_proto,
          ws_url: ENV['PHALA_NODE_URL_FOR_WORKERS']
        }
      }
    end
  end
end

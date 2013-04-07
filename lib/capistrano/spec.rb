module Capistrano
  module Spec
    module ConfigurationExtension
      def get(remote_path, path, options={}, &block)
        gets[remote_path] = {:path => path, :options => options, :block => block}
      end

      def gets
        @gets ||= {}
      end

      def run(cmd, options={}, &block)
        runs[cmd] = {:options => options, :block => block}
        if (stub = stubbed_commands[cmd])
          raise ::Capistrano::CommandError if stub[:fail]
          raise stub[:raise] if stub[:raise]

          if block_given?
            data = stub[:data]
            data = stub[:with].call(cmd) if stub[:with].respond_to? :call

            block.call stub[:channel], stub[:stream], data
          end
        end
      end

      def runs
        @runs ||= {}
      end

      def upload(from, to, options={}, &block)
        uploads[from] = {:to => to, :options => options, :block => block}
      end

      def uploads
        @uploads ||= {}
      end

      def stubbed_commands
        @stubbed_commands ||= {}
      end

      def stub_command(command, options = {})
        stubbed_commands[command] = { :stream => :out, :data => '' }.merge options
      end
    end

    module Helpers
      def find_callback(configuration, on, task)
        if task.kind_of?(String)
          task = configuration.find_task(task)
        end

        callbacks = configuration.callbacks[on]

        callbacks && callbacks.select do |task_callback|
          task_callback.applies_to?(task) || task_callback.source == task.fully_qualified_name
        end
      end

    end

    module Matchers
      extend ::RSpec::Matchers::DSL

      define :callback do |task_name|
        extend Helpers

        match do |configuration|
          @task = configuration.find_task(task_name)
          callbacks = find_callback(configuration, @on, @task)

          if callbacks
            @callback = callbacks.first

            if @callback && @after_task_name
              @after_task = configuration.find_task(@after_task_name)
              @callback.applies_to?(@after_task)
            elsif @callback && @before_task_name
              @before_task = configuration.find_task(@before_task_name)
              @callback.applies_to?(@before_task)
            else
              ! @callback.nil?
            end
          else
            false
          end
        end

        def on(on)
          @on = on
          self
        end

        def before(before_task_name)
          @on = :before
          @before_task_name = before_task_name
          self
        end

        def after(after_task_name)
          @on = :after
          @after_task_name = after_task_name
          self
        end

        failure_message_for_should do |actual|
          if @after_task_name
            "expected configuration to callback #{task_name.inspect} #{@on} #{@after_task_name.inspect}, but did not"
          elsif @before_task_name
            "expected configuration to callback #{task_name.inspect} #{@on} #{@before_task_name.inspect}, but did not"
          else
            "expected configuration to callback #{task_name.inspect} on #{@on}, but did not"
          end
        end

      end

      define :have_gotten do |path|
        match do |configuration|

          get = configuration.gets[path]
          if @to
            get && get[:path] == @to
          else
            get
          end
        end

        def to(to)
          @to = to
          self
        end

        failure_message_for_should do |actual|
          if @to
            "expected configuration to get #{path} to #{@to}, but did not"
          else
            "expected configuration to get #{path}, but did not"
          end
        end
      end

      define :have_uploaded do |path|
        @to = nil # Reset `to` because it will influence next match otherwise.

        match do |configuration|
          uploads = configuration.uploads
          uploads = uploads.select { |f, u| f == path } if path
          uploads = uploads.select { |f, u| u[:to] == @to } if @to
          uploads.any?
        end

        def to(to)
          @to = to
          self
        end

        failure_message_for_should do |actual|
          if @to
            "expected configuration to upload #{path} to #{@to}, but did not"
          else
            "expected configuration to upload #{path}, but did not"
          end
        end
      end

      define :have_run do |cmd|

        match do |configuration|
          @configuration = configuration
          run = configuration.runs[cmd]
          run
        end

        failure_message_for_should do |actual|
          runs = @configuration.runs.keys.join "\n  "
          "expected configuration to run `#{cmd}`, but did not. Has run: \n  #{runs}"
        end

      end

    end
  end
end


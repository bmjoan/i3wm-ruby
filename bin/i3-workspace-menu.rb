#!/usr/bin/ruby
# ^^^ direct path to avoid rbenv or similar wrappers for fastest startup time
# #!/usr/bin/env ruby
require 'optparse'
require 'ostruct'
require 'json'

MENU_COMMAND = ['dmenu', '-b', '-f']


def main
  options, menu_args = ArgsParser.parse ARGV

  ws_names    = get_active_workspaces
  selected_ws = show_menu(ws_names, menu_args)
  if options.move_client
    move_to_workspace(selected_ws)
  else
    switch_workspace(selected_ws)
  end
end

class ArgsParser
  def self.parse(args)
    options = OpenStruct.new
    options.move_client = false

    opt_parser = OptionParser.new do |opts|
      opts.banner = 'Workspaces switcher for i3'
      opts.on '-mv', 'move client to a workspace' do
        |movecl|
        options.move_client = true
      end
    end

    opt_parser.parse!(args)
    [options, args]
  end
end

# Returns a list of currently active workspaces
def get_active_workspaces
  IO.popen(['i3-msg', '-t', 'get_workspaces']) do |output|
    JSON.parse(output.read).collect {|h| h['name']}
  end
end

# Displays menu with given options, returns selected item"
def show_menu(options, args)
  IO.popen(MENU_COMMAND + args, 'r+') do |fm|
    fm.puts options.join("\n")
    fm.close_write
    sel = fm.gets
    sel.nil? ? sel : sel.strip
  end
end

# Switches i3 to a given workspace
def switch_workspace(name)
  if !(name.nil? || name.empty?)
    spawn('i3-msg', 'workspace', name)
  end
end

# Moves focused client to a given workspace
def move_to_workspace(name)
  if !(name.nil? || name.empty?)
    spawn('i3-msg', 'move to workspace', name)
  end
end


if __FILE__ == $0
  main
end

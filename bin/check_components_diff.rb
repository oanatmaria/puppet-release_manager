#! /usr/bin/ruby
# frozen_string_literal: true

require_relative '../lib/release_manager'
require_relative '../lib/components_diff/components_diff'
require 'terminal-table'
require 'colorize'

class Presenter
  attr_reader :rows

  def initialize
    @rows = []
  end

  def present
    ReleaseManager::ComponentsDiff::Runner.run(ARGV[0] || 'master').each do |component, details|
      print_details component, details
      next if /core|runtime|api/.match?(component)

      flag = details[:commits].any?
      add_row component, details[:tag], flag
    end
    table = Terminal::Table.new rows: rows
    puts table
  end

  private

  def print_details(component, details)
    puts "\n"
    puts "#{component} - #{details[:tag]}"
    details[:commits].each do |commit|
      puts "  #{commit.sha} - #{commit.message.delete("\n")}"
    end
  end

  def add_row(component, tag, flagok = false)
    revision = tag.match(/[0-9]+\.[0-9]+\.[0-9]+/)
    if flagok
      rows << [component, revision.to_s.green, nil]
    else
      new_revision = change_revision revision.to_s
      rows << [component, revision.to_s.red, new_revision.green]
    end
  end

  def change_revision(revision)
    index = revision.rindex('.')
    wo_end = revision.slice(0, index + 1)
    changed = (revision.slice(index + 1, revision.length - index).to_i + 1).to_s
    wo_end.concat(changed)
  end
end

Presenter.new.present

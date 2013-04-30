module IssuesExportHelper
  DELIMITER_LINE = '=' * 5

  def add_journals(csv, query, options={})
    csv_with_journals = FCSV.generate do |newcsv|
      FCSV.parse(Redmine::CodesetUtil.to_utf8(csv, 'CP932'), :headers => true, :return_headers => true) do |row|
        if row.header_row?
          newcsv << row.fields + [t(:label_history)]
        else
          if options[:single_cell] == 'single'
            histories = Issue.find(row.fields.first).journals.map do |j|
              j.user.name + ' (' + format_time(j.created_on) + ')' + "\n" +
                (j.details.empty? ? "\n" : "\n" + j.details.reduce('') {|s, d| s += '* ' + show_detail(d, true) + "\n"} + "\n") +
                (j.notes.nil? ? '' : j.notes.gsub(/\r\n?/, "\n"))
            end
            newcsv << row.fields + [histories.join("\n" + DELIMITER_LINE + "\n")]
          else
            newcsv << row.fields + Issue.find(row.fields.first).journals.map do |j|
              j.user.name + ' (' + format_time(j.created_on) + ')' + "\n" +
                j.details.map {|d| show_detail(d, true)}.join("\n") + "\n" +
                (j.notes.nil? ? '' : j.notes)
            end
          end
        end
      end
    end
    Redmine::CodesetUtil.from_utf8(csv_with_journals, 'CP932')
  end
end

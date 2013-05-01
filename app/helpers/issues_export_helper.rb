module IssuesExportHelper
  DELIMITER_LINE = '=' * 5
  EXCEL_LIMIT = 32767 - 16

  def add_journals(csv, query, options={})
    csv_with_journals = FCSV.generate do |newcsv|
      FCSV.parse(Redmine::CodesetUtil.to_utf8(csv, 'CP932'), :headers => true, :return_headers => true) do |row|
        if row.header_row?
          newcsv << row.fields + [t(:label_history)]
        else
          journals = Issue.find(row.fields.first).journals
          journals = journals.order('id DESC') if options[:order] == 'desc'
          journals = journals.limit(options[:limit].to_i) if options[:limit].to_i > 0
          if options[:single_cell] == 'single'
            histories = journals.map do |j|
              j.user.name + ' (' + format_time(j.created_on) + ')' + "\n" +
                (j.details.empty? ? "\n" : "\n" + j.details.reduce('') {|s, d| s += '* ' + show_detail(d, true) + "\n"} + "\n") +
                (j.notes.nil? ? '' : j.notes.gsub(/\r\n?/, "\n"))
            end
            histories = histories.join("\n" + DELIMITER_LINE + "\n")
            histories = histories[0, EXCEL_LIMIT] if options[:excel_limit] && histories.length > EXCEL_LIMIT
            newcsv << row.fields + [histories]
          else
            newcsv << row.fields + journals.map do |j|
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

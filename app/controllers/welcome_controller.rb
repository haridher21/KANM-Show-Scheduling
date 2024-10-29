class WelcomeController < ApplicationController
  def index
    # Use a different directory in test environment to isolate real data
    upload_path = Rails.env.test? ? "#{Rails.root}/tmp/test_uploads" : "#{Rails.root}/public/uploads"

    # Check for CSV and XLSX files in the specified directory
    @csv_files = Dir.glob("#{upload_path}/*.{csv,xlsx}")
  end

  def handle_files
    case params[:action_type]
    when "generate_schedule"
      # upload_path = Rails.env.test? ? "#{Rails.root}/tmp/test_uploads" : "#{Rails.root}/public/uploads"
      selected_files = params[:selected_files]
      if selected_files.present? && selected_files.size == 1
        parse_selected_files(selected_files)

      else
        redirect_to welcome_path, alert: "Please select exactly one file to parse."
      end

    when "delete_files"
      if params[:selected_files].present?
        delete_csv_files(params[:selected_files])
        redirect_to welcome_path, notice: "Selected files have been deleted."
      else
        redirect_to welcome_path, alert: "No files selected for deletion."
      end

    else
      redirect_to welcome_path, alert: "Invalid action."
    end
  end

  private

  def delete_csv_files(selected_files)
    # Use a different directory in test environment to isolate real data
    upload_path = Rails.env.test? ? "#{Rails.root}/tmp/test_uploads" : "#{Rails.root}/public/uploads"

    if params[:selected_files].present?
      params[:selected_files].each do |file_name|
        file_path = Rails.root.join(upload_path, file_name)


        if File.exist?(file_path)
          File.delete(file_path)
        else
          logger.warn("#{file_name} does not exist.")
        end
      end
    end
  end

  def parse_selected_files(selected_files)
    upload_path = Rails.env.test? ? "#{Rails.root}/tmp/test_uploads" : "#{Rails.root}/public/uploads"

    selected_files.each do |file_name|
      file_path = Rails.root.join(upload_path, file_name)
      parse_and_create_radio_jockeys(file_path)
    end
    redirect_to calendar_path
  end

  def parse_and_create_radio_jockeys(file_path)
    RadioJockey.delete_all
    xlsx = Roo::Spreadsheet.open(file_path.to_s)

    first_sheet = xlsx.sheet(0)
    i = 1
    first_sheet.each_row_streaming(offset: 1) do |row|  # Skip header row
      # Create a new RadioJockey record for each row
      i = i + 1
      if row[13]&.value.to_s == "Returning DJ"
        numeric_value = row[26].cell_value.to_f
        best_hour = (numeric_value * 24).round.to_s

        RadioJockey.create!(
          timestamp: row[0]&.value.to_s || "",
          first_name: row[4]&.value.to_s || "",
          last_name: row[5]&.value.to_s || "",
          UIN: row[8]&.value.to_s || "",
          expected_grad: row[9]&.value.to_s || "",
          member_type: row[13]&.value.to_s || "",
          retaining: row[14]&.value.to_s || "", # this is dummy data from us, column location may change
          semesters_in_KANM: row[15]&.value.to_s || "",
          show_name: row[22]&.value.to_s || "",
          DJ_name: row[23]&.value.to_s || "",
          best_day: row[25]&.value.to_s || "",
          best_hour: best_hour,
          alt_mon: xlsx.cell("AB", i).to_s,
          alt_tue: xlsx.cell("AC", i).to_s,
          alt_wed: xlsx.cell("AD", i).to_s,
          alt_thu: xlsx.cell("AE", i).to_s,
          alt_fri: xlsx.cell("AF", i).to_s,
          alt_sat: xlsx.cell("AG", i).to_s,
          alt_sun: xlsx.cell("AH", i).to_s,
          un_feb: xlsx.cell("AI", i).to_s,
          un_mar: xlsx.cell("AJ", i).to_s,
          un_apr: xlsx.cell("AK", i).to_s,
          un_may: xlsx.cell("AL", i).to_s
        )
      end
    end

    second_sheet = xlsx.sheet(1)
    i = 1
    second_sheet.each_row_streaming(offset: 1) do |row|  # Skip header row
      # Create a new RadioJockey record for each row
      i = i + 1
      if row[21]&.value.to_s == "New DJ"
        numeric_value = row[35].cell_value.to_f
        best_hour = (numeric_value * 24).round.to_s

        RadioJockey.create!(
          timestamp: row[0]&.value.to_s,
          first_name: row[5].value.nil? ? "" : row[5].value.to_s,
          last_name: row[6].value.nil? ? "" : row[6].value.to_s,
          UIN: row[10].value.nil? ? "" : row[10].value.to_s,
          expected_grad: row[13].value.nil? ? "" : row[13].value.to_s,
          member_type: row[21].value.nil? ? "" : row[21].value.to_s,
          retaining: "No",
          semesters_in_KANM: row[19].value.nil? ? "" : row[19].value.to_s,
          show_name: row[31].value.nil? ? "" : row[31].value.to_s,
          DJ_name: row[32].value.nil? ? "" : row[32].value.to_s,
          best_day: row[34].value.nil? ? "" : row[34].value.to_s,
          best_hour: best_hour,
          alt_mon: xlsx.cell("AK", i).to_s,
          alt_tue: xlsx.cell("AL", i).to_s,
          alt_wed: xlsx.cell("AM", i).to_s,
          alt_thu: xlsx.cell("AN", i).to_s,
          alt_fri: xlsx.cell("AO", i).to_s,
          alt_sat: xlsx.cell("AP", i).to_s,
          alt_sun: xlsx.cell("AQ", i).to_s,
          un_feb: xlsx.cell("AS", i).to_s,
          un_mar: xlsx.cell("AT", i).to_s,
          un_apr: xlsx.cell("AU", i).to_s,
          un_may: xlsx.cell("AV", i).to_s
        )
      end
    end

  rescue => e
    Rails.logger.error("Error while parsing XLSX: #{e.message}")
  # Handle any error, maybe rollback if necessary
end
end

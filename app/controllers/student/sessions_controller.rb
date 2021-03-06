class Student::SessionsController < Devise::SessionsController
  def create
    if can?(:create, AttendanceRecord.new) && params[:pair][:email] != ''
      pair_sign_in
    elsif can?(:create, AttendanceRecord.new)
      super
      @attendance_record = AttendanceRecord.create(student: current_student)
    else
      super
    end
  end

private

  def pair_sign_in
    student = Student.find_by(email: params[:student][:email])
    pair = Student.find_by(email: params[:pair][:email])

    if student.try(:valid_password?, params[:student][:password]) && pair.try(:valid_password?, params[:pair][:password])
      attendance_records = [AttendanceRecord.new(student: student, pair_id: pair.id),
                            AttendanceRecord.new(student: pair, pair_id: student.id)]
      if attendance_records.all? { |record| record.save }
        student_names = attendance_records.map { |attendance_record| attendance_record.student.name }
        flash[:notice] = "Welcome #{student_names.join(' and ')}."
        redirect_to after_sign_in_path_for(student)
      else
        flash[:alert] = "Something went wrong: " + attendance_records.first.errors.full_messages.join(", ")
        self.resource = Student.new
        render 'devise/sessions/new'
      end
    else
      flash[:alert] = "Invalid email or password."
      self.resource = Student.new
      render 'devise/sessions/new'
    end
  end
end

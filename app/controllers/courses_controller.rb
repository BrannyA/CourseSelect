class CoursesController < ApplicationController

  before_action :student_logged_in, only: [:select, :quit, :list]
  before_action :teacher_logged_in, only: [:new, :create, :edit, :destroy, :update, :open, :close]#add open by qiao
  before_action :logged_in, only: :index

  #-------------------------for teachers----------------------

  def new
    @course=Course.new
  end

  def create
    @course = Course.new(course_params)
    if @course.save
      current_user.teaching_courses<<@course
      redirect_to courses_path, flash: {success: "新课程申请成功"}
    else
      flash[:warning] = "信息填写有误,请重试"
      render 'new'
    end
  end

  def edit
    @course=Course.find_by_id(params[:id])
  end

  def update
    @course = Course.find_by_id(params[:id])
    if @course.update_attributes(course_params)
      flash={:info => "更新成功"}
    else
      flash={:warning => "更新失败"}
    end
    redirect_to courses_path, flash: flash
  end

  def open
    @course=Course.find_by_id(params[:id])
    @course.update_attributes(open: true)
    redirect_to courses_path, flash: {:success => "已经成功开启该课程:#{ @course.name}"}
  end

  def close
    @course=Course.find_by_id(params[:id])
    @course.update_attributes(open: false)
    redirect_to courses_path, flash: {:success => "已经成功关闭该课程:#{ @course.name}"}
  end

  def destroy
    @course=Course.find_by_id(params[:id])
    current_user.teaching_courses.delete(@course)
    @course.destroy
    flash={:success => "成功删除课程: #{@course.name}"}
    redirect_to courses_path, flash: flash
  end

  #-------------------------for students----------------------

  def list
    #-------QiaoCode--------
    @courses = Course.where(:open=>true).paginate(page: params[:page], per_page: 4)
    @course = @courses-current_user.courses
    tmp=[]
    @course.each do |course|
      if course.open==true
        tmp<<course
      end
    end
    @course=tmp
  end

  def list
    excluded_courses_id = [-1]
    current_user.courses.each do |course|
      excluded_courses_id << course.id
    end
    @courses = Course.where("open = ? and id not in (?)", true, excluded_courses_id).paginate(page: params[:page], per_page: 4)
    if params.has_key?(:course_time)
      ctime = params[:course_time]
      ctype = params[:course_type]
      cname = params[:course_name] 
      if ctime != "不限" and ctype == "不限" and cname == ""
        @courses = Course.where("open = ? and course_time like ? and id not in (?)", true, "%#{ctime}%", excluded_courses_id).paginate(page: params[:page], per_page: 4)
      elsif ctime == "不限" and ctype != "不限" and cname == ""
        @courses = Course.where("open = ? and course_type = ? and id not in (?)", true, ctype, excluded_courses_id).paginate(page: params[:page], per_page: 4)
      elsif ctime == "不限" and ctype == "不限" and cname != ""
        @courses = Course.where("open = ? and name like ? and id not in (?)", true, "%#{cname}%", excluded_courses_id).paginate(page: params[:page], per_page: 4)
      elsif ctime != "不限" and ctype != "不限" and cname == ""
        @courses = Course.where("open = ? and course_time like ? and course_type = ? and id not in (?)", true, "%#{ctime}%", ctype, excluded_courses_id).paginate(page: params[:page], per_page: 4)
      elsif ctime != "不限" and ctype == "不限" and cname != ""
        @courses = Course.where("open = ? and course_time like ? and name like ? and id not in (?)", true, "%#{ctime}%", "%#{cname}%", excluded_courses_id).paginate(page: params[:page], per_page: 4)
      elsif ctime == "不限" and ctype != "不限" and cname != ""
        @courses = Course.where("open = ? and course_type = ? and name like ? and id not in (?)", true, ctype, "%#{cname}%", excluded_courses_id).paginate(page: params[:page], per_page: 4)
      elsif ctime != "不限" and ctype != "不限" and cname != ""
        @courses = Course.where("open = ? and  course_time like ? and course_type = ? and name like ? and id not in (?)", true, "%#{ctime}%", ctype, "%#{cname}%", excluded_courses_id).paginate(page: params[:page], per_page: 4)
      end  
    end
  end 
  
  def hint
    @courses = current_user.courses
  end

  def table

  end

  def select
    @course=Course.find_by_id(params[:id])
    current_user.courses.each do |c|
      if c.course_time[0..4] == @course.course_time[0..4]
        flash={:warning => "与已选课程:#{c.name}时间冲突"}
        redirect_to list_courses_path, flash: flash
        return
      end
      if c.course_time[5] == @course.course_time[3] or c.course_time[3] == @course.course_time[5] and c.course_time[0..2] == @course.course_time[0..2]
        flash={:warning => "与已选课程:#{c.name}时间冲突"}
        redirect_to list_courses_path, flash: flash
        return
      end
    end
    current_user.courses<<@course
    sc = 0
    @course.users.each do |u|
      if !u.teacher and !u.admin
        sc += 1
      end
    end
    @course.student_num = sc
    @course.save
    flash={:suceess => "成功选择课程: #{@course.name}"}
    redirect_to courses_path, flash: flash
  end

  def quit
    @course=Course.find_by_id(params[:id])
    current_user.courses.delete(@course)
    sc = 0
    @course.users.each do |u|
      if !u.teacher and !u.admin
        sc -= 1
      end
    end
    @course.student_num = sc
    @course.save
    flash={:success => "成功退选课程: #{@course.name}"}
    redirect_to courses_path, flash: flash
  end


  #-------------------------for both teachers and students----------------------

  def index
    @course=current_user.teaching_courses.paginate(page: params[:page], per_page: 4) if teacher_logged_in?
    @course=current_user.courses.paginate(page: params[:page], per_page: 4) if student_logged_in?
  end


  private

  # Confirms a student logged-in user.
  def student_logged_in
    unless student_logged_in?
      redirect_to root_url, flash: {danger: '请登陆'}
    end
  end

  # Confirms a teacher logged-in user.
  def teacher_logged_in
    unless teacher_logged_in?
      redirect_to root_url, flash: {danger: '请登陆'}
    end
  end

  # Confirms a  logged-in user.
  def logged_in
    unless logged_in?
      redirect_to root_url, flash: {danger: '请登陆'}
    end
  end

  def course_params
    params.require(:course).permit(:course_code, :name, :course_type, :teaching_type, :exam_type,
                                   :credit, :limit_num, :class_room, :course_time, :course_week)
  end


end

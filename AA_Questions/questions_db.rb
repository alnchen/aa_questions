require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end


class User
  attr_accessor :fname, :lname
  attr_reader :id

  def self.find_by_id(id)
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    return nil if user.empty?

    User.new(user.first)
  end

  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL
    return nil if user.empty?

    User.new(user.first)
  end

  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end

  def create
    raise "#{self} already in database" unless @id.nil?
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
      INSERT INTO
        users (fname, lname)
      VALUES
        (?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" if @id.nil?
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
      UPDATE
        users
      SET
        fname = ?, lname = ?
      WHERE
        id = ?
    SQL
  end

  def authored_questions
    raise "#{self} not in database" if @id.nil?
    Question.find_by_author_id(@id)
  end

  def authored_replies
    raise "#{self} not in database" if @id.nil?
    Reply.find_by_user_id(@id)
  end
end


class Question

  attr_accessor :title, :body, :user_id
  attr_reader :id

  def self.find_by_id(id)
    question = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    return nil if question.empty?

    Question.new(question.first)
  end

  def self.find_by_title(title)
    questions = QuestionsDatabase.instance.execute(<<-SQL, title)
      SELECT
        *
      FROM
        questions
      WHERE
        title = ?
    SQL
    return nil if questions.empty?

    questions.map { |question| Question.new(question) }
  end

  def self.find_by_author_id(author_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        user_id = ?
    SQL

    return nil if questions.empty?
    questions.map { |question| Question.new(question) }
  end

  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @user_id = options['user_id']
  end

  def create
    raise "#{self} already in database" unless @id.nil?
    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @user_id)
      INSERT INTO
        questions (title, body, user_id)
      VALUES
        (?, ?, ?)
    SQL

    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} not in database" if @id.nil?
    QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @user_id, @id)
      UPDATE
        questions
      SET
        title = ?, body = ?, user_id = ?
      WHERE
        id = ?
    SQL
  end

  def author
    User.find_by_id(@user_id)
  end

  def replies
    Reply.find_by_question_id(@id)
  end
end

class Reply
  attr_accessor :question_id, :parent_id, :user_id, :body
  attr_reader :id

  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    return nil if reply.empty?

    Reply.new(reply.first)
  end

  def self.find_by_user_id(user_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?
    SQL

    return nil if replies.empty?
    replies.map { |reply| Reply.new(reply) }
  end

  def self.find_by_question_id(question_id)
    replies = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL

    return nil if replies.empty?
    replies.map { |reply| Reply.new(reply) }
  end

  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent_id = options['parent_id']
    @user_id = options['user_id']
    @body = options['body']
  end

  def create
    raise "#{self} is already in database" unless @id.nil?
    QuestionsDatabase.instance.execute(<<-SQL, @question_id, @parent_id, @user_id, @body)
      INSERT INTO
        replies (question_id, parent_id, user_id, body)
      VALUES
        (?, ?, ?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end

  def update
    raise "#{self} is not in database" if @id.nil?
    QuestionsDatabase.instance.execute(<<-SQL, @question_id, @parent_id, @user_id, @body, @id)
      UPDATE
        replies
      SET
        question_id = ?, parent_id = ?, user_id = ?, body = ?
      WHERE
        id = ?
    SQL
  end

  def author
    User.find_by_id(@user_id)
  end

  def question
    Question.find_by_id(@question_id)
  end

  def parent_reply
    self.class.find_by_id(@parent_id)
  end

  def child_replies
    replies = QuestionsDatabase.instance.execute(<<-SQL, @id)
      SELECT
        *
      FROM
        replies
      WHERE
        parent_id = ?
    SQL

    replies.map { |reply| Reply.new(reply) }
  end


end

require_relative 'questions_db.rb'
require_relative 'user.rb'
require_relative 'question.rb'
require_relative 'reply.rb'

class QuestionFollow
  def self.followers_for_question_id(question_id)
    followers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        users.id, users.fname, users.lname
      FROM
        users
      JOIN
        question_follows ON question_follows.user_id = users.id
      JOIN
        questions ON questions.id = question_follows.question_id
      WHERE
        questions.id = ?
    SQL

    return nil if followers.empty?
    followers.map { |follower| User.new(follower) }
  end

  def self.followed_questions_for_user_id(user_id)
    questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        questions.id, questions.title, questions.body, questions.user_id
      FROM
        questions
      JOIN
        question_follows ON question_follows.question_id = questions.id
      JOIN
        users ON question_follows.user_id = users.id
      WHERE
        users.id = ?
    SQL

    return nil if questions.empty?
    questions.map { |question| Question.new(question) }
  end

  def self.most_followed_questions(n)
    most_followed_questions = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        question.id, question.title, question.body, question.user_id
      FROM
        questions
      JOIN
        question_follows ON question_follows.question_id = questions.id
      GROUP BY
        question.id
      ORDER BY
        COUNT(*) DESC
      LIMIT
        ?
    SQL
    return nil if most_followed_questions.empty?

    most_followed_questions.map { |question| Question.new(question) }
  end
end

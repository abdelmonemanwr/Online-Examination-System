USE [OnlineExaminationSystemDB]
GO
/****** Object:  StoredProcedure [dbo].[examGeneration]    Script Date: 3/2/2024 7:10:18 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
alter proc [dbo].[examGeneration] @crsName varchar(100), @mcq int, @tf int, @studID int
as
begin

	declare @t table(quesId int, question varchar(100), choice varchar(100), marks int)

	declare @t_ids table(quesId int, question varchar(100), marks int)
	
	declare @examID int
	select @examID = count(*)+1
	from Exams
	
	-- InsertExam @examID, 'course exam', 3, 100
	insert into Exams values (@examID, @crsName, 3, 100)

	-- crs id
	declare @ID int
	select @ID = c.Crs_ID
	from Courses c
	where c.Name = @crsName;

	-- pick random ques ids
	insert into @t_ids
	select top (@mcq)
	q.Q_Id, q.Name ,q.Marks
	from Questions q 
	where q.type = 'mcq' and q.Crs_Id = @ID 
	order by NEWID()
	
	insert into @t_ids
	select top (@tf)
	q.Q_Id, q.Name ,q.Marks
	from Questions q 
	where q.type = 'tf' and q.Crs_Id = @ID 
	order by NEWID()


	--select * from @t_ids
    insert into @t
    select tt.quesId, tt.question, qch.Choice, tt.marks
    from @t_ids tt inner join Ques_Choices qch
        on tt.quesId = qch.Ques_id
    order by tt.quesId


	insert into StudentCourseExam (Crs_Id, St_Id, Exam_Id)
	values (@ID, @studID, @examID)

    ;WITH RankedData AS (
        SELECT quesId,
            ROW_NUMBER() OVER (ORDER BY quesId) AS Rank
        FROM @t_ids
    )

    insert into Exam_Ques_St (Ques_id, St_id, Ex_id)
	select quesId, @studID , @examID
    FROM RankedData
    WHERE Rank <= 10;

	select * from @t order by quesId
end
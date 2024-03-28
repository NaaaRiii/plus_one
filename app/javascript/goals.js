export function setupTaskCheckboxes() {
  const taskCheckboxes = document.querySelectorAll('.task-checkbox');

  taskCheckboxes.forEach(function(checkbox, index) {
    checkbox.addEventListener('change', function() {
      const smallGoalId = checkbox.dataset.smallGoalId;
      if (!smallGoalId) {
        console.error('Error: No smallGoalId found for this checkbox.');
        return;
      }

      const smallGoalDiv = document.querySelector(`div[data-small-goal-id="${smallGoalId}"]`);
      if (!smallGoalDiv) {
        console.error(`Error: No .small-goal div found for smallGoalId ${smallGoalId}.`);
        return;
      }

      const allTaskCheckboxes = smallGoalDiv.querySelectorAll('.task-checkbox');
      const allCompleted = Array.from(allTaskCheckboxes).every(chk => chk.checked);

      const smallGoalCompleteButton = smallGoalDiv.querySelector('.small-goal-complete-button');
      if (!smallGoalCompleteButton) {
        console.error('Error: No .small-goal-complete-button found.');
        return;
      }

      if (allCompleted) {
        smallGoalCompleteButton.style.display = 'block';
      } else {
        smallGoalCompleteButton.style.display = 'none';
      }
    });
  });
}

document.addEventListener('turbo:load', function() {
  // 各小目標のタスクのチェック状態を確認する関数
  function checkTasksAndToggleCompleteButton(smallGoalDiv) {
    const allTaskCheckboxes = smallGoalDiv.querySelectorAll('.task-checkbox');
    const allCompleted = Array.from(allTaskCheckboxes).every(chk => chk.checked);
    
    const smallGoalCompleteButton = smallGoalDiv.querySelector('.small-goal-complete-button');
    if (smallGoalCompleteButton) {
      if (allCompleted) {
        smallGoalCompleteButton.style.display = 'block';
      } else {
        smallGoalCompleteButton.style.display = 'none';
      }
    }
  }

  // ページ読み込み時に各小目標についてチェックを行う
  document.querySelectorAll('.small-goal').forEach(smallGoalDiv => {
    checkTasksAndToggleCompleteButton(smallGoalDiv);
  });

  const taskCheckboxes = document.querySelectorAll('.task-checkbox');

  taskCheckboxes.forEach(function(checkbox, index) {
    checkbox.addEventListener('change', function() {
      const smallGoalId = checkbox.dataset.smallGoalId;
      if (!smallGoalId) {
        console.error('Error: No smallGoalId found for this checkbox.'); // smallGoalIdがない場合のエラーログ
        return;
      }

      const smallGoalDiv = document.querySelector(`div[data-small-goal-id="${smallGoalId}"]`);
      if (!smallGoalDiv) {
        console.error(`Error: No .small-goal div found for smallGoalId ${smallGoalId}.`); // 対応する.small-goal divがない場合のエラーログ
        return;
      }

      const allTaskCheckboxes = smallGoalDiv.querySelectorAll('.task-checkbox');
      const allCompleted = Array.from(allTaskCheckboxes).every(chk => chk.checked);
      console.log(`All tasks completed: ${allCompleted}`); // すべてのタスクが完了しているかのログ

      // すべてのタスクが完了している場合は、完了ボタンを表示
      const smallGoalCompleteButton = smallGoalDiv.querySelector('.small-goal-complete-button');
      if (!smallGoalCompleteButton) {
        console.error('Error: No .small-goal-complete-button found.'); // 完了ボタンがない場合のエラーログ
        return;
      }

      if (allCompleted) {
        console.log('All tasks are completed. Showing the complete button.'); // すべて完了していれば完了ボタンを表示するログ
        smallGoalCompleteButton.style.display = 'block';
      } else {
        console.log('Not all tasks are completed. Hiding the complete button.'); // すべて完了していなければ完了ボタンを非表示にするログ
        smallGoalCompleteButton.style.display = 'none';
      }
    });
  });
});

//すべてにチェックを入れるボタン 不要になったら削除
document.addEventListener('turbo:load', function() {
  document.getElementById('check-all-tasks').addEventListener('click', function() {
    document.querySelectorAll('.task-checkbox').forEach(function(checkbox) {
      checkbox.checked = true;
    });
  });
});
//すべてにチェックを入れるボタン 不要になったら削除

document.addEventListener('turbo:load', function() {
  document.querySelectorAll('.task-checkbox').forEach(function(checkbox) {
    checkbox.addEventListener('change', function() {
      console.log('Checkbox changed!');
      const taskId = this.value;
      const completed = this.checked;
      // Ajaxを使用してサーバーに状態更新を送信
      fetch(`/tasks/${taskId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ completed: completed })
      });
    });
  });
});

//一瞬表示されるエラーメッセージを非表示にする 期待通りではない
//document.addEventListener("turbo:load", function() {
//  console.log('Turbo loaded!!!');
//  const errorExplanation = document.getElementById("error_explanation");
//  if (errorExplanation) {
//    errorExplanation.innerHTML = '';
//  }
//});
import { setupTaskCheckboxes } from './app/javascript/goals';

describe('setupTaskCheckboxes', () => {
  beforeEach(() => {
    document.body.innerHTML = `
      <div class="small-goal" data-small-goal-id="1">
        <input type="checkbox" class="task-checkbox" data-small-goal-id="1">
        <input type="checkbox" class="task-checkbox" data-small-goal-id="1">
        <button class="small-goal-complete-button" style="display: none;"></button>
      </div>
      <div class="small-goal" data-small-goal-id="2">
        <input type="checkbox" class="task-checkbox" data-small-goal-id="2">
        <input type="checkbox" class="task-checkbox" data-small-goal-id="2">
        <button class="small-goal-complete-button" style="display: none;"></button>
      </div>
    `;
  });

  test('sets up event listeners for task checkboxes', () => {
    setupTaskCheckboxes();
    const taskCheckboxes = document.querySelectorAll('.task-checkbox');
    taskCheckboxes.forEach((checkbox) => {
      expect(checkbox).toHaveProperty('onchange');
    });
  });

  test('shows the complete button when all tasks are completed', () => {
    setupTaskCheckboxes();
    const taskCheckboxes = document.querySelectorAll('.task-checkbox');
    taskCheckboxes.forEach((checkbox) => {
      checkbox.checked = true;
      checkbox.dispatchEvent(new Event('change'));
    });
    const completeButtons = document.querySelectorAll('.small-goal-complete-button');
    completeButtons.forEach((button) => {
      expect(button.style.display).toBe('block');
    });
  });

  test('hides the complete button when not all tasks are completed', () => {
    setupTaskCheckboxes();
    const taskCheckboxes = document.querySelectorAll('.task-checkbox');
    taskCheckboxes[0].checked = true;
    taskCheckboxes[0].dispatchEvent(new Event('change'));
    const completeButtons = document.querySelectorAll('.small-goal-complete-button');
    completeButtons.forEach((button) => {
      expect(button.style.display).toBe('none');
    });
  });
});

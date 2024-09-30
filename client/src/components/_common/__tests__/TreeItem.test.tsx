import React from 'react';
import { Router, BrowserRouter } from 'react-router-dom';
import { createMemoryHistory } from 'history';
import { render, screen } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { SimpleTreeView } from '@mui/x-tree-view/SimpleTreeView';
import TreeItemLabel from 'components/TestSuite/TestSuiteTree/TreeItemLabel';
import ThemeProvider from 'components/ThemeProvider';
import CustomTreeItem from '../CustomTreeItem';
import { mockedTestSuite } from '../__mocked_data__/mockData';
import { expect, test } from 'vitest';

test('renders custom TreeItem', () => {
  render(
    <BrowserRouter>
      <ThemeProvider>
        <SimpleTreeView>
          <CustomTreeItem
            itemId={mockedTestSuite.id}
            label={<TreeItemLabel runnable={mockedTestSuite} />}
            ContentProps={{ testId: mockedTestSuite.id } as any}
          />
        </SimpleTreeView>
      </ThemeProvider>
    </BrowserRouter>,
  );

  const treeItemElement = screen.getByRole('treeitem');
  expect(treeItemElement).toBeInTheDocument();
});

test('TreeItem expansion should not be toggled when label is clicked', async () => {
  render(
    <BrowserRouter>
      <ThemeProvider>
        <SimpleTreeView expandedItems={[mockedTestSuite.id]}>
          <CustomTreeItem
            itemId={mockedTestSuite.id}
            label={<TreeItemLabel runnable={mockedTestSuite} />}
            ContentProps={{ testId: mockedTestSuite.id } as any}
          >
            <></>
          </CustomTreeItem>
        </SimpleTreeView>
      </ThemeProvider>
    </BrowserRouter>,
  );

  const labelElement = screen.getAllByTestId('tiLabel', { exact: false })[0];
  const treeItemElement = screen.getAllByRole('treeitem')[0];
  expect(labelElement).toBeInTheDocument();
  expect(treeItemElement).toHaveAttribute('aria-expanded', 'true');

  await userEvent.click(labelElement);
  expect(treeItemElement).toHaveAttribute('aria-expanded', 'true');
});

test('clicking on TreeItem should navigate to group or test instance', async () => {
  const history = createMemoryHistory();
  history.push(`/${mockedTestSuite.id}/:test_session_id`);

  render(
    <Router location={history.location} navigator={history}>
      <ThemeProvider>
        <SimpleTreeView>
          <CustomTreeItem
            itemId={mockedTestSuite.id}
            label={<TreeItemLabel runnable={mockedTestSuite} />}
            ContentProps={{ testId: mockedTestSuite.id } as any}
          />
        </SimpleTreeView>
      </ThemeProvider>
    </Router>,
  );

  const labelElement = screen.getAllByTestId('tiLabel', { exact: false })[0];
  expect(labelElement).toBeInTheDocument();

  await userEvent.click(labelElement);
  expect(history.location.hash).toBe(`#${mockedTestSuite.id}`);
});

import * as React from 'react';
import TreeItem, {
  TreeItemProps,
  useTreeItem,
  TreeItemContentProps,
  treeItemClasses,
} from '@mui/lab/TreeItem';
import clsx from 'clsx';
import Typography from '@mui/material/Typography';
import { styled } from '@mui/material/styles';
import { useHistory } from 'react-router-dom';

interface CustomTreeItemContentProps extends TreeItemContentProps {
  testId?: string;
}

const CustomContent = React.forwardRef(function CustomContent(
  props: CustomTreeItemContentProps,
  ref
) {
  const {
    classes,
    className,
    label,
    nodeId,
    icon: iconProp,
    expansionIcon,
    displayIcon,
    testId,
  } = props;

  const {
    disabled,
    expanded,
    selected,
    focused,
    handleExpansion,
    handleSelection,
    preventSelection,
  } = useTreeItem(nodeId);

  const history = useHistory();

  const icon = iconProp || expansionIcon || displayIcon;

  const handleMouseDown = (event: React.MouseEvent<HTMLDivElement, MouseEvent>) => {
    preventSelection(event);
  };

  const handleExpansionAction = (
    event: React.MouseEvent<HTMLDivElement, MouseEvent> | React.KeyboardEvent<HTMLDivElement>
  ) => {
    handleExpansion(event);
  };

  const handleSelectionAction = (
    event: React.MouseEvent<HTMLDivElement, MouseEvent> | React.KeyboardEvent<HTMLDivElement>
  ) => {
    handleSelection(event);
    if (testId) history.push(`#${testId}`);
  };

  return (
    <div
      className={clsx(className, classes.root, {
        [classes.expanded]: expanded,
        [classes.selected]: selected,
        [classes.focused]: focused,
        [classes.disabled]: disabled,
      })}
      onMouseDown={handleMouseDown}
      ref={ref as React.Ref<HTMLDivElement>}
    >
      <div
        onClick={(e) => {
          handleExpansionAction(e);
          handleSelectionAction(e);
        }}
        onKeyPress={(e) => {
          handleExpansionAction(e);
          handleSelectionAction(e);
        }}
        className={classes.iconContainer}
      >
        {icon}
      </div>
      <Typography
        onClick={handleSelectionAction}
        onKeyPress={handleSelectionAction}
        component="div"
        className={classes.label}
        tabIndex={0}
      >
        {label}
      </Typography>
    </div>
  );
});

const CustomTreeItem = styled((props: TreeItemProps) => (
  <TreeItem ContentComponent={CustomContent} {...props} />
))(() => ({
  [`& .${treeItemClasses.selected}`]: {
    backgroundColor: 'rgba(248, 139, 48, 0.2) !important',
  },
  [`& .${treeItemClasses.content}`]: {
    width: 'auto',
    padding: '0 20px',
  },
}));

export default CustomTreeItem;

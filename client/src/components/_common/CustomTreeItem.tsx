import * as React from 'react';
import {
  TreeItem,
  TreeItemProps,
  useTreeItemState,
  TreeItemContentProps,
  treeItemClasses,
} from '@mui/x-tree-view/TreeItem';
import clsx from 'clsx';
import Typography from '@mui/material/Typography';
import { styled } from '@mui/material/styles';
import { useNavigate } from 'react-router-dom';
import lightTheme from '~/styles/theme';

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
    itemId,
    icon: iconProp,
    expansionIcon,
    displayIcon,
    testId,
  } = props;

  // These imported TreeItem values only accept MouseEvent types
  // so KeyboardEvents need to be type asserted
  const {
    disabled,
    expanded,
    selected,
    focused,
    handleExpansion,
    handleSelection,
    preventSelection,
  } = useTreeItemState(itemId);

  const navigate = useNavigate();

  const icon = iconProp || expansionIcon || displayIcon;

  const handleInteractionEvent = (
    event: React.MouseEvent<HTMLDivElement, MouseEvent> | React.KeyboardEvent<HTMLDivElement>
  ) => {
    const e = event.target as HTMLInputElement;
    const iconTestName = e.getAttribute('data-testid');

    // Disable default selection behavior
    preventSelection(event as React.MouseEvent<HTMLDivElement, MouseEvent>);

    // Do not select if clicking on expansion icon
    if (iconTestName !== 'ChevronRightIcon' && iconTestName !== 'ExpandMoreIcon') {
      handleSelectionAction(event);
    }
  };

  const handleExpansionAction = (
    event: React.MouseEvent<HTMLDivElement, MouseEvent> | React.KeyboardEvent<HTMLDivElement>
  ) => {
    handleExpansion(event as React.MouseEvent<HTMLDivElement, MouseEvent>);
  };

  const handleSelectionAction = (
    event: React.MouseEvent<HTMLDivElement, MouseEvent> | React.KeyboardEvent<HTMLDivElement>
  ) => {
    handleSelection(event as React.MouseEvent<HTMLDivElement, MouseEvent>);
    if (testId) navigate(`#${testId}`);
  };

  return (
    <div
      className={clsx(className, classes.root, {
        [classes.expanded]: expanded,
        [classes.selected]: selected,
        [classes.focused]: focused,
        [classes.disabled]: disabled,
      })}
      onMouseDown={handleInteractionEvent}
      onKeyDown={(e) => {
        if (e.key === 'Enter') handleInteractionEvent(e);
      }}
      ref={ref as React.Ref<HTMLDivElement>}
    >
      <div
        onClick={handleExpansionAction}
        onKeyDown={(e) => {
          if (e.key === 'Enter') handleExpansionAction(e);
        }}
        className={classes.iconContainer}
      >
        {icon}
      </div>
      <Typography component="div" className={classes.label} tabIndex={0}>
        {label}
      </Typography>
    </div>
  );
});

const CustomTreeItem = styled((props: TreeItemProps) => (
  <TreeItem ContentComponent={CustomContent} {...props} />
))(() => ({
  [`& .${treeItemClasses.selected}`]: {
    backgroundColor: `${lightTheme.palette.common.orangeLight} !important`,
  },
  [`& .${treeItemClasses.content}`]: {
    width: 'auto',
    padding: '0 20px',
  },
}));

export default CustomTreeItem;

import React, { FC } from 'react';
import Markdown from 'react-markdown';
import remarkGfm from 'remark-gfm';
import { enqueueSnackbar } from 'notistack';

import {
  Accordion,
  AccordionDetails,
  AccordionSummary,
  Box,
  Divider,
  Link,
  List,
  ListItem,
  ListItemText,
  Typography,
} from '@mui/material';
import ExpandMoreIcon from '@mui/icons-material/ExpandMore';
import { getSingleRequirement } from '~/api/RequirementsApi';
import { Requirement, TestGroup } from '~/models/testSuiteModels';
import useStyles from './styles';
import { shouldShowRequirementsButton } from '~/components/TestSuite/TestSuiteUtilities';
import RequirementsModal from '~/components/TestSuite/Requirements/RequirementsModal';

interface NestedDescriptionPanelProps {
  testGroup: TestGroup;
}

const NestedDescriptionPanel: FC<NestedDescriptionPanelProps> = ({ testGroup }) => {
  const { classes } = useStyles();
  const [showRequirements, setShowRequirements] = React.useState(false);
  const [requirements, setRequirements] = React.useState<Requirement[]>([]);
  const [descriptionMouseHover, setDescriptionMouseHover] = React.useState(false);
  const showRequirementsButton = shouldShowRequirementsButton(testGroup);

  const showRequirementsClick = () => {
    const requirementIds = testGroup.verifies_requirements;
    if (requirementIds) {
      Promise.all(requirementIds.map((requirementId) => getSingleRequirement(requirementId)))
        .then((resolvedValues) => {
          setRequirements(resolvedValues.filter((r) => !!r));
          setShowRequirements(true);
        })
        .catch((e: Error) => {
          enqueueSnackbar(`Error fetching specification requirements: ${e.message}`, {
            variant: 'error',
          });
        });
    }
  };

  return (
    <Box py={1} className={classes.descriptionContainer}>
      <Accordion
        disableGutters
        elevation={0}
        key={`${testGroup.id}-description`}
        className={classes.accordion}
        slotProps={{ transition: { unmountOnExit: true } }}
        onMouseEnter={() => setDescriptionMouseHover(true)}
        onMouseLeave={() => setDescriptionMouseHover(false)}
      >
        <AccordionSummary
          id={descriptionMouseHover ? '' : `${testGroup.id}-description-summary`}
          aria-controls={`${testGroup.id}-description-detail`}
          expandIcon={<ExpandMoreIcon sx={{ padding: '0 5px' }} />}
          sx={{ userSelect: 'auto' }}
        >
          <List sx={{ p: 0 }}>
            <ListItem sx={{ p: 0 }}>
              <ListItemText
                primary={
                  <Typography className={classes.descriptionHeader}>
                    About {testGroup.short_title || testGroup.title}
                  </Typography>
                }
              />
            </ListItem>
          </List>
        </AccordionSummary>
        <Divider />
        <AccordionDetails
          title={descriptionMouseHover ? '' : `${testGroup.id}-description-detail`}
          className={classes.descriptionDetailContainer}
        >
          <Box className={`${classes.accordionDetail} ${classes.description}`}>
            <Markdown remarkPlugins={[remarkGfm]}>{testGroup.description as string}</Markdown>
            {showRequirementsButton && (
              <Box display="flex" justifyContent="end" minWidth="fit-content" pt={1}>
                <Link
                  color="secondary"
                  className={classes.textButton}
                  onClick={showRequirementsClick}
                >
                  View Specification Requirements
                </Link>
              </Box>
            )}
          </Box>
        </AccordionDetails>
      </Accordion>
      {requirements && showRequirementsButton && (
        <RequirementsModal
          requirements={requirements}
          modalVisible={showRequirements}
          hideModal={() => setShowRequirements(false)}
        />
      )}
    </Box>
  );
};

export default NestedDescriptionPanel;

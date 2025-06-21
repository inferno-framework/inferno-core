import React, { FC } from 'react';
import { enqueueSnackbar } from 'notistack';
import { Box, Link } from '@mui/material';
import { getSingleRequirement } from '~/api/RequirementsApi';
import { Requirement, Runnable } from '~/models/testSuiteModels';
import { shouldShowRequirementsButton } from '~/components/TestSuite/TestSuiteUtilities';
import RequirementsModal from '~/components/TestSuite/Requirements/RequirementsModal';
import useStyles from './styles';

interface RequirementsModalButtonProps {
  runnable: Runnable;
}

const RequirementsModalButton: FC<RequirementsModalButtonProps> = ({ runnable }) => {
  const { classes } = useStyles();
  const [requirements, setRequirements] = React.useState<Requirement[]>([]);
  const [showRequirements, setShowRequirements] = React.useState(false);

  const showRequirementsClick = () => {
    const requirementIds = runnable.verifies_requirements;
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
    <>
      <Box display="flex" justifyContent="end" minWidth="fit-content" p={2}>
        <Link color="secondary" className={classes.textButton} onClick={showRequirementsClick}>
          View Specification Requirements
        </Link>
      </Box>
      {requirements && shouldShowRequirementsButton(runnable) && (
        <RequirementsModal
          requirements={requirements}
          modalVisible={showRequirements}
          hideModal={() => setShowRequirements(false)}
        />
      )}
    </>
  );
};

export default RequirementsModalButton;

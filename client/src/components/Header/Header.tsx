import React, { FC } from 'react';
import useStyles from './styles';
import icon from 'images/inferno_icon.png';
import { AppBar, Box, Button, Link, Stack, Toolbar, Typography } from '@mui/material';
import { useHistory } from 'react-router-dom';
import NoteAddIcon from '@mui/icons-material/NoteAdd';
import { getStaticPath } from 'api/infernoApiService';
import { PresetSummary } from 'models/testSuiteModels';
import PresetsModal from 'components/PresetsModal/PresetsModal';

export interface HeaderProps {
  suiteTitle?: string;
  suiteVersion?: string;
  presets?: PresetSummary[];
  testSessionId?: string;
  getSessionData?: (testSessionId: string) => void;
}

const Header: FC<HeaderProps> = ({
  suiteTitle,
  suiteVersion,
  presets,
  testSessionId,
  getSessionData,
}) => {
  const styles = useStyles();
  const history = useHistory();
  const [presetModalVisible, setPresetModalVisible] = React.useState(false);

  const returnHome = () => {
    history.push('/');
  };

  const presetButton = () => {
    if (!presets || presets.length < 1 || !testSessionId || !getSessionData) {
      return <></>;
    } else {
      return (
        <Box>
          <Button
            color="secondary"
            onClick={() => setPresetModalVisible(true)}
            variant="outlined"
            disableElevation
            size="small"
          >
            Use predefined input
          </Button>
          <PresetsModal
            modalVisible={presetModalVisible}
            presets={presets}
            testSessionId={testSessionId}
            getSessionData={getSessionData}
            setModalVisible={setPresetModalVisible}
          />
        </Box>
      );
    }
  };

  return suiteTitle ? (
    <AppBar color="default" className={styles.appbar}>
      <Toolbar className={styles.toolbar}>
        <Box display="flex" justifyContent="center">
          <Link href="/">
            <img
              src={getStaticPath(icon as string)}
              alt="Inferno logo - start new session"
              className={styles.logo}
            />
          </Link>
          <Box className={styles.titleContainer}>
            <Typography variant="h5" component="h1" className={styles.title}>
              {suiteTitle}
            </Typography>
            {suiteVersion && (
              <Typography variant="overline" className={styles.version}>
                {`v.${suiteVersion}`}
              </Typography>
            )}
          </Box>
        </Box>
        <Stack direction="row" spacing={2}>
          {presetButton()}
          <Button
            disableElevation
            color="secondary"
            size="small"
            variant="contained"
            startIcon={<NoteAddIcon />}
            onClick={returnHome}
          >
            New Session
          </Button>
        </Stack>
      </Toolbar>
    </AppBar>
  ) : (
    <></>
  );
};

export default Header;

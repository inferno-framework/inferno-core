const createSession = () => {
  // Get Suite ID
  const suiteId = Array.from(document.getElementsByTagName('input'))
    .filter((elem) => elem.checked && elem.name === 'suite')
    .map((elem) => elem.value)[0]; // should only have one selected option

  // Get checked options and map to id and value
  const checkedOptions = Array.from(document.getElementsByTagName('input'))
    .filter((elem) => elem.checked && elem.name !== 'suite' && $(elem).is(':visible'))
    .map((elem) => ({
      id: elem.name,
      value: elem.value
    }));

  const postUrl = `api/test_sessions?test_suite_id=${suiteId}`;
  const postBody = {
    preset_id: null,
    suite_options: checkedOptions,
  };
  fetch(postUrl, { method: 'POST', body: JSON.stringify(postBody) })
    .then((response) => response.json())
    .then((result) => {
      const sessionId = result.id;
      if (!result) {
        throw Error('Session could not be created. Please check input values.');
      } else if (!sessionId || sessionId === 'undefined') {
        throw Error('Session could not be created. Session ID is undefined.');
      } else {
        location.href = `test_sessions/${sessionId}`;
      }
    })
    .catch((e) => {
      showToast(e);
    });
};

// Returns a list of all tags as strings from a test kit element
const getTags = (tags, elem) => {
  Array.from(elem.children).forEach((e) => {
    if (e.className === 'tag') {
      tags.push(e.innerText);
    }
    getTags(tags, e);
  });
  return tags;
};

// Returns the level of maturity for a given test kit element
const getMaturity = (elem) => {
  let innerText = '';
  Array.from(elem.children).forEach((e) => {
    if (e.className === 'maturity') {
      innerText = e.innerText;
      return e.innerText;
    }

    // ignore the pinned icon for traversal, which is hit last
    if(e.nodeName !== 'I'){
      innerText = getMaturity(e);
    }

  });

  return innerText;
};

// Returns true if test kit should be shown based on standard filter
const filterTag = (testKit, standard) => {
  if (!standard) return true;
  const tags = getTags([], testKit);
  return tags.includes(standard) || standard === 'All Tags';
};

// Returns true if test kit should be shown based on maturity filter
const filterMaturity = (testKit, maturity) => {
  if (!maturity) return true;
  const testKitMaturity = getMaturity(testKit);
  return testKitMaturity.includes(maturity) || maturity === 'All Levels';
};

// Returns true if test kit should be shown based on text filter
const filterText = (testKit, text) => {
  const testKitText = testKit.innerText.toLowerCase();
  return testKitText.includes(text);
};

// Ensure all applied filters take effect
const filterAll = (text, standard, maturity) => {
  for (let testKit of document.getElementsByName('test-kit')) {
    showElement(
      filterText(testKit, text) && filterTag(testKit, standard) && filterMaturity(testKit, maturity),
      testKit,
    );
  }
};
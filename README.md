# HOME-ECER_EWER

Experimentation in the HOME corpus with a coupled model which performs HTR and NER in one step. We employ PyLaia () to build and train the optical model and SRILM () to construct a character 8-gram. Both models are combined via the usage of Kaldi ().

The results can be evaluted with the proposed ECER and EWER metrics, which are available at () and read the hypotheses at Named Entity level.

# HOME-ECER_EWER

Experimentation in the HOME corpus (https://icar-us.eu/cooperation/online-portals/monasterium-net/) with a coupled model which performs HTR and NER in one step. We employ PyLaia (https://github.com/jpuigcerver/PyLaia) to build and train the optical model and SRILM (http://www.speech.sri.com/projects/srilm/) to construct a character 8-gram. Both models are combined via the usage of Kaldi (https://kaldi-asr.org/doc/).

The results can be evaluted with the proposed ECER and EWER metrics, which are invoked in the n-best experiment and available at scripts/.

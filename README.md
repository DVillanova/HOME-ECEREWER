# HOME-ECER_EWER

Experimentation in the National Archives corpus (https://icar-us.eu/cooperation/online-portals/monasterium-net/), which was presented in [1] with a coupled model which performs HTR and NER in one step. We employ PyLaia (https://github.com/jpuigcerver/PyLaia) to build and train the optical model and SRILM (http://www.speech.sri.com/projects/srilm/) to construct a character 8-gram. Both models are combined via the usage of Kaldi (https://kaldi-asr.org/doc/).

The implementation has been tested with the usage of the Docker environment presented. The results can be evaluted with the proposed ECER and EWER metrics, which are invoked in the n-best experiment and available at scripts/dist_edicion_custom_saturated.py.

[1] E. Boroş et al., "A comparison of sequential and combined approaches for named entity recognition in a corpus of handwritten medieval charters," 2020 17th International Conference on Frontiers in Handwriting Recognition (ICFHR), 2020, pp. 79-84, doi: 10.1109/ICFHR2020.2020.00025.

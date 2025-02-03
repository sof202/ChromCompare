# Main Script Explanation

The main script found in `.../JobSubmission/` creates a variety of similarity
metrics for your chosen two ChromHMM models and combines these into a single
metric for you to [interpret].

## The metrics

There are two types of metrics that are produced by this script. One tackles
how similar the emission parameters are between each pair of states between the
two models, whilst the other aims to assess the spatial similarity. Both are
an obvious requirement when comparing states between two models (as these 
are the two main features of hidden Markov models).

### Emission similarity

To keep in line with tools like
[ChromOptimise](https://github.com/sof202/ChromOptimise) and
[ChromHMM](https://compbio.mit.edu/ChromHMM/), states between the two models
are compared using Euclidean distance. State pairs that have a small Euclidean
distance between them are similar as they signify a similar combination of
epigenetic marks.

### Spatial similarity

WARNING: For spatial similarity to make sense, both models must be trained on
the same genome build.

Spatial similarity is the feature not natively present in ChromHMM's command
list. Considering HMM models can have multiple states with very similar
emission parameters, emission similarity isn't enough to make sound comparisons
between the states of two models (*i.e.* as 2 states in model A may match with
1 state from model B, making it difficult to tell which pair is most
applicable). 

Spatial similarity is calculated by the use of fold enrichment, the formula for
which is taken from ChromHMM (as ChromHMM uses this for enrichment in known
genomic features like CGIs). The formula is applied to each state pair between
the two models, such that a higher value implies the two states tend to occupy
the same regions of the genome. Uncertainty is somewhat baked into this formula
and so extraordinary large numbers will only be observed when there is an exact
match between two states that are both very rare.

#### Formula

As mentioned, this formula is taken directly from ChromHMM. It is defined by:

(C/A)/(B/D)

Where:

- A is the number of bases in the reference state
- B is the number of bases in the comparison state
- C is the number of bases in the overlap in the reference state and the
comparison state
- D is the number of bases in the genome

#### Margins

Due to the nature of hidden Markov model training, spatial similarity between
two states can be ruined by a slight shift in state assignment (especially when
smaller bin sizes are used). For example, consider the following:

---xxx---xxx---xxx

000---000---000---

If the bin size used above was 20bp, the state 'x' in the first model could
be considered to be similar is spatial assignment to state '0' in the second.
However, under the fold enrichment formula, there is **no** spatial similarity
reported at all.

To get around this quirk, ChromCompare allows you to add a buffer region around
each state to increase the fold enrichment. Although this will increase the
fold enrichment for every state pair (especially is the margins are very
large), situations like the above will recieve higher fold enrichments over
others.

The configuration file created during
[setup](https://github.com/sof202/ChromCompare/tree/main#setup) allows you to
find spatial similarities for any number of different margin sizes. It is
recommended to at least have one spatial similarity score calculated using a
margin. For this margin, we recommend to use the same value as the bin size
used when training the models (if the models use different bin sizes, pick the 
smaller of the two).

## Combination process

After calculating similarity metrics for both spatial and emission properties,
the final step of the main script is to combine all of these into one single
score (for interpretability). Each similarity score is stored in matrix form
(where each value corresponds with the similarity score between the state pair
given by the row and column number) and a linear combination is calculated
using [user specified weights](#deciding-on-weights). 

There is however one small problem that needs to be addressed before taking a
linear combination. The score given by emission similarity favours a smaller
number (closer in Euclidean distance) and the spatial similarity score favours
a greater number (higher fold enrichment). In order to make these compatible, a
transformation is applied to the emission similarity score matrix which is
given by:

E = s_max * (1 - e/e_max)

Where:

- E is the new emission similarity matrix
- e is the old emission similarity matrix
- e_max is the maximum emission similarity (highest Euclidean distance)
- s_max is the maximum spatial similarity (highest fold enrichment over all
matrices)


### Deciding on weights

There isn't any concrete guidance on how to decide upon what weights to use
here just yet. This is because the decisions you make will be influenced by
what you are exactly looking for. In general, we suggest that the emissions
similarity matrix accounts for most of the weight as this is the most concrete
measure of similarity. Then, for the spatial similarity matrices, larger
margins should be favoured less (smaller weights) as values will be naturally
inflated.

It is likely that you will need to use wildly different weights depending on
the two models you are comparing and the original datasets you are using. For
example, if you trained one model with a bin size of 300 and the other with
200, you would expect states to tend to not line up (due to the 100bp
discrepency). As such a margin size of 100bp (or 200bp) would be favoured more
than usual (perhaps more than the scores without margins). 

Turning on `$DEBUG_MODE` in the config file will allow you to look at the
intermediate similarity matrices (before they are combined), which may assist
you in deciding which metrics are more useful.

It should be noted that these similarity metrics are purely heuristic and
should used with caution. The main purpose of the information produced by these
scripts is to assist you with later analysis. It can be helpful to know that
state xxx in model A has no suitable comparison to any state in model B. It can
be useful to know that although state xxx in model A has similar emission
parameters to states yyy and zzz in model B, a better state pair should be
between xxx and yyy due to their fold enrichment.



# Reference figures

Original mlatlas recreations of well-known ML architectures and standard textbook concepts,
sourced from the LLM-comparison references and the free/open textbook survey
(see [`../../docs/free-textbooks.md`](../../docs/free-textbooks.md)). Each file rebuilds the
*architecture or concept* — a public fact — in mlatlas's own print-first style; the source
figures were used only to confirm parameters, never traced or copied.

Grouped by topic:

| folder | what's inside |
|---|---|
| `llm/` | LLM architecture comparisons (Llama / OLMo / DeepSeek / Qwen / Gemma / Mistral / GPT-OSS / Grok / GLM / Kimi …) and mechanism figures (MHA·GQA·MLA, dense·MoE FFN, pre/post-norm, sliding-window & sink attention) |
| `transformers/` | the Transformer, encoder-decoder, multi-head block, ViT, Bahdanau/Luong cross-attention |
| `vision/` | CNN architectures (VGG / ResNet / U-Net / DenseNet / AlexNet·LeNet / Inception), detection & segmentation (SSD, Faster-RCNN, DeepLab-ASPP, anchors/IoU, transposed conv), and geometry (image pyramid, optical flow, epipolar, SfM, stereo, NeRF, Gaussian splatting) |
| `sequence-nlp/` | RNN / LSTM / GRU, seq2seq, beam search, word2vec / SGNS, BERT MLM·NSP, BPE, n-gram, parse trees, CTC, ASR pipeline |
| `generative/` | GAN, autoencoder family, normalizing flow, variational inference / ELBO, reparameterization |
| `probabilistic/` | Bayes nets, factor / Tanner graphs, MRF, CRF, junction tree, message passing, RBM/DBN, EM, GMM, GP, kernels, MCMC, Kalman / state-space, particle filter, influence diagrams, DBN, computational graph |
| `reinforcement/` | agent-environment loop, MDP/POMDP, gridworld, actor-critic, backup diagram, policy iteration / gradient, DQN, MCTS, AlphaZero, POMDP belief, alpha-vectors, Dyna, TD-spectrum, world model, RL taxonomy |
| `classical-theory/` | decision tree / forest / boosting, SVM, bias-variance, k-fold CV, confusion matrix, PCA, gradient descent, kernel trick, bootstrap, ROC/PR, k-means, dendrogram, regularization paths, VC / PAC / SRM, surrogate losses, orthogonal projection, ReLU regions |
| `graph-ssl/` | GAT, GraphSAGE, node-embedding enc-dec, KG embedding, graph generation, Siamese/triplet, SimCLR, BYOL, capsule routing, spatial transformer |

Build any one with `typst compile --root . examples/refs/<folder>/<name>.typ`, or all via
`./tools/render-all.sh`.

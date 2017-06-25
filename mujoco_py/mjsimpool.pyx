
cdef class MjSimPool(object):
    """
    Keeps a pool of multiple MjSims and enables stepping them quickly
    in parallel.
    """
    # Arrays of pointers to mjDatas and mjModels for fast multithreaded access
    cdef mjModel **_models
    cdef mjData **_datas

    # List of MjSim objects that can be accessed directly.
    cdef readonly list sims
    # Number of .step substeps.
    cdef readonly int nsubsteps

    def __cinit__(self, list sims, int nsubsteps=1):
        """
        Args:
            - sims ([PyMjModel] list): list of sims to add to the pool
            - nsubsteps (int): number of substeps to run on `.step`. The
                individual model `nsubstep`s will be ignored.
        """
        self.sims = sims
        self.nsubsteps = nsubsteps
        self._allocate_data_pointers()

    def reset(self, nsims=None):
        """
        Resets all simulations in pool.
        If nsims is specified, than only the first nsims simulator are reset.
        """
        length = self.nsims

        if nsims is not None:
            if nsims > self.nsims:
                raise ValueError("nsims is larger than pool size")
            length = nsims

        for i in range(length):
            self.sims[i].reset()

    def forward(self, nsims=None):
        """
        Calls `mj_forward` on all simulations in parallel.
        If nsims is specified, than only the first nsims simulator are forwarded.
        """
        cdef int i
        cdef int length = self.nsims

        if nsims is not None:
            if nsims > self.nsims:
                raise ValueError("nsims is larger than pool size")
            length = nsims

        # See explanation in MjSimPool.step() for why we wrap warnings this way
        with wrap_mujoco_warning():
            with nogil, parallel():
                for i in prange(length, schedule='guided'):
                    mj_forward(self._models[i], self._datas[i]);

    def step(self, nsims=None):
        """
        Calls `mj_step` on all simulations in parallel, with `nsubsteps` as
        specified on `MjSimPool` instance creation.
        If nsims is specified, than only the first nsims simulator are stepped.
        """
        cdef int i, j
        cdef int length = self.nsims

        if nsims is not None:
            if nsims > self.nsims:
                raise ValueError("nsims is larger than pool size")
            length = nsims

        for sim in self.sims[:length]:
            sim.step_udd()

        # Wrapping these calls to mj_step is tricky, since they're parallelized
        # and can't access the GIL or global python objects.
        # Because we expect to have fatal warnings, we'll just wrap the entire
        # section, and if any call ends up setting an exception we'll raise.
        with wrap_mujoco_warning():
            with nogil, parallel():
                for i in prange(length, schedule='guided'):
                    for j in range(self.nsubsteps):
                        mj_step(self._models[i], self._datas[i]);

    @property
    def nsims(self):
        """
        Number of simulations in the pool.
        """
        return len(self.sims)

    @staticmethod
    def create_from_sim(sim, nsims):
        sims = [MjSim(sim.model, udd_callback=sim.udd_callback)
                for _ in range(nsims)]
        return MjSimPool(sims, nsubsteps=sim.nsubsteps)

    cdef _allocate_data_pointers(self):
        self._models = <mjModel**>malloc(self.nsims * sizeof(mjModel*))
        self._datas = <mjData**>malloc(self.nsims * sizeof(mjData*))
        for i in range(self.nsims):
            sim = <MjSim> self.sims[i]
            self._models[i] = sim.model.ptr
            self._datas[i] = sim.data.ptr

    def __dealloc__(self):
        free(self._datas)
        free(self._models)

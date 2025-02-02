% Generic helper to compare various solvers (possibly with various options)
% on various problems, in Manopt.
%
% First version: August 10, 2018
%
% Naman Agarwal, Nicolas Boumal, Brian Bullins, Coralia Cartis
% https://github.com/NicolasBoumal/arc

clear; clc;

% Fix randomness
rng(2019);

cd example_problems;

%% Build a collection of problems

problems = { ...
        elliptope_SDP(1000) ...
        maxcut(50)...
        truncated_svd_problem([], 210, 300, 25), ...
        rotation_synchronization(3, 100, .75)
};
% problems = { ...
%         maxcut(22)

% };
% 
nproblems = numel(problems);

% Each problem structure must have a 'name' field (a string) for display.

% Pick one initial guess for each problem (will be passed to all solvers).
% One possible improvement to this code would be to allow for more than one
% initial guess per problem, to show agregated statistics.
% If the problem structure suggests an initial guess, we use that one.
inits = cell(size(problems));
for P = 1 : nproblems
    if isfield(problems{P}, 'x0')
        inits{P} = problems{P}.x0;
    else
        inits{P} = problems{P}.M.rand();
    end
end

% Build a collection of solvers, together with accompanying options
% structures. You can have the same solver multiple times with different
% options if that's relevant. Notice that we add the 'name' field, which is
% used to display results.
solvers_and_options = {struct('solver', @trustregions, 'subproblemsolver', @trs_tCG_cached, 'name', 'RTR cached') ...
                	struct('solver', @trustregions, 'subproblemsolver', @trs_tCG, 'name', 'RTR'), ...
%                 	struct('solver', @trustregions, 'subproblemsolver', @trs_gep, 'name', 'TRS_gep'), ...
                 ... % struct('solver', @arc, 'theta', 0.25, 'subproblemsolver', @arc_lanczos, 'sigma_min', 1e-10, 'name', 'ARC (Lanczos, \theta = .25)'), ...
                 ... % struct('solver', @arc, 'theta', 2.00, 'subproblemsolver', @arc_lanczos, 'sigma_min', 1e-10, 'name', 'ARC (Lanczos, \theta = 2)'), ...
                 ... % struct('solver', @arc, 'theta', 0.02, 'subproblemsolver', @arc_lanczos, 'sigma_min', 1e-10, 'name', 'ARC (Lanczos, \theta = .02)'), ...
                 ... % struct('solver', @arc, 'theta', .50, 'subproblemstop', 'grule',  'subproblemsolver', @arc_lanczos, 'name', 'ARC (Lanczos, \theta = .5, grule)'), ...
                 ... % struct('solver', @arc, 'gamma_1', 0.1, 'gamma_2', 5, 'theta', .25, 'subproblemstop', 'sqrule', 'subproblemsolver', @arc_conjugate_gradient, 'name', 'ARC (NLCG, \theta = .25, sqrule, gamma_1 = 0.1, gamma_2 = 5)'), ...
                 ... % struct('solver', @arc, 'gamma_1', 0.0, 'gamma_2', 5, 'theta', .25, 'subproblemstop', 'sqrule', 'subproblemsolver', @arc_conjugate_gradient, 'name', 'ARC (NLCG, \theta = .25, sqrule, gamma_1 = 0.0, gamma_2 = 5)'), ...
                 ... % struct('solver', @arc, 'gamma_1', 0.1, 'gamma_2', 2, 'theta', 0.25, 'subproblemstop', 'sqrule', 'subproblemsolver', @arc_conjugate_gradient, 'sigma_min', 1e-10, 'name', 'ARC (NLCG, \theta = .25)'), ...
                 ... % struct('solver', @arc, 'gamma_1', 0.1, 'gamma_2', 2, 'theta', 2.00, 'subproblemstop', 'sqrule', 'subproblemsolver', @arc_conjugate_gradient, 'sigma_min', 1e-10, 'name', 'ARC (NLCG, \theta = 2)'), ...
                 ... % struct('solver', @arc, 'gamma_1', 0.1, 'gamma_2', 2, 'theta', 0.02, 'subproblemstop', 'sqrule', 'subproblemsolver', @arc_conjugate_gradient, 'sigma_min', 1e-10, 'name', 'ARC (NLCG, \theta = .02)'), ...
                 ... % struct('solver', @arc, 'gamma_1', 0.1, 'gamma_2', 10, 'theta', .25, 'subproblemstop', 'sqrule', 'subproblemsolver', @arc_conjugate_gradient, 'name', 'ARC (NLCG, \theta = .25, sqrule, gamma_1 = 0.1, gamma_2 = 10)'), ...
                 ... % struct('solver', @arc, 'gamma_1', 0.1, 'gamma_2', 2, 'theta', 1e-6, 'subproblemstop', 'sqrule', 'subproblemsolver', @arc_conjugate_gradient, 'name', 'ARC (NLCG, \theta = 1e-4, sqrule, gamma_1 = 0.1, gamma_2 = 2)'), ...
                 ... % struct('solver', @arc, 'gamma_1', 0.0, 'gamma_2', 2, 'theta', .25, 'subproblemstop', 'sqrule', 'subproblemsolver', @arc_conjugate_gradient, 'name', 'ARC (NLCG, \theta = .25, sqrule, gamma_1 = 0.0, gamma_2 = 2)'), ...
                 ... % struct('solver', @arc, 'gamma_1', 0.1, 'gamma_2', 2, 'theta', .25, 'subproblemstop', 'sqrule', 'subproblemsolver', @arc_conjugate_gradient, 'rho_regularization', 0, 'name', 'ARC (NLCG, \theta = .25, sqrule, gamma_1 = 0.1, gamma_2 = 2, rho_regularization = 0)'), ...
                 ... % struct('solver', @arc, 'theta', .25, 'subproblemstop', 'grule',  'subproblemsolver', @arc_conjugate_gradient, 'name', 'ARC (NLCG, \theta = .25, grule)'), ...
                 ... % struct('solver', @arc, 'theta', .25, 'subproblemstop', 'srule',  'subproblemsolver', @arc_conjugate_gradient, 'name', 'ARC (NLCG, \theta = .25, srule)'), ...
                 ... % struct('solver', @arc, 'theta', .25, 'subproblemstop', 'ssrule', 'subproblemsolver', @arc_conjugate_gradient, 'name', 'ARC (NLCG, \theta = .25, ssrule)'), ...
                 ... % struct('solver', @arc, 'theta', 50, 'name', 'ARC \theta = 50'), ...
                 ... % struct('solver', @rlbfgs, 'name', 'RLBFGS'), ...
                 ... % struct('solver', @conjugategradient, 'beta_type', 'F-R', 'name', 'CG-FR'), ...
                 ... % struct('solver', @conjugategradient, 'beta_type', 'P-R', 'name', 'CG-PR'), ...
                 ... % struct('solver', @conjugategradient, 'beta_type', 'H-S', 'maxiter', 10000, 'name', 'CG-HS'), ...
                 ... % struct('solver', @conjugategradient, 'beta_type', 'H-Z', 'name', 'CG-HZ'), ...
                 ... % struct('solver', @barzilaiborwein, 'name', 'BB'), ...
                 ... % struct('solver', @steepestdescent, 'name', 'GD'), ...
                       };
nsolvers = numel(solvers_and_options);
                   
% Add common options to all
for S = 1 : nsolvers
    solvers_and_options{S}.statsfun = statsfunhelper(statscounters({'hesscalls', 'gradhesscalls'}));
    solvers_and_options{S}.tolgradnorm = 1e-9;
    solvers_and_options{S}.verbosity = 0;
end

%% Run all solvers on all problems

% Reminder: when benchmarking computation time, it is important to:
%  1) Use a dedicated computer (or at least minimize other running programs)
%  2) Run the code once without recording (so that Matlab will JIT the
%     code, that is, use just-in-time compilation), then run a second time
%     to actually collect data.
idstring = datestr(now(), 'mmm_dd_yyyy_HHMMSS');
fileIdName= sprintf('compare_solvers_%s', idstring);
disp(fileIdName);
fileID = fopen(strcat(fileIdName, '.txt'),'w');

infos = cell(nproblems, nsolvers);
for P = 1 : nproblems
    fprintf('Solving %s\n', problems{P}.name);
    for S = 1 : nsolvers
        fprintf(fileID, '\twith %s.\n', solvers_and_options{S}.name);
        [x, cost, info, ~] = manoptsolve(problems{P}, inits{P}, solvers_and_options{S});
        infos{P, S} = info;
        fprintf(fileID, '.\n');
    end
    f1 = fieldnames(infos{P, 1});
%     f2 = fieldnames(infos{P, 2});
%     assert(isequaln(f1, f2));
    rejnum = length([infos{P, 1}(:).accepted]) - sum([infos{P, 1}(:).accepted]);
    totaliter = length([infos{P, 1}(:).accepted]);
    fprintf(fileID, 'rejections/total = %d / %d\n', rejnum, totaliter);
    for i=1:length(f1)
        if strcmp(f1{i},'time') || strcmp(f1{i}, 'hesscalls') || strcmp(f1{i}, 'gradhesscalls') || strcmp(f1{i},'timeit') || strcmp(f1{i}, 'memorytCG_MB')
            continue;
        end
%         assert(isequaln([infos{P, 1}(:).(f1{i})],[infos{P, 2}(:).(f1{i})]));
    end
end

cd ..;

%% Plot results
subplot_rows = 4;
subplot_cols = 2;
assert(subplot_rows * subplot_cols >= nproblems, ...
       sprintf('Choose subplot size to fit all %d problems.', nproblems));
xmetric = {'iter',     'time',     'gradhesscalls', 'iter',};
xscale  = {'linear',   'linear',   'linear', 'linear', };
ymetric = {'gradnorm', 'gradnorm', 'gradnorm', 'memorytCG_MB'};
yscale  = {'log',      'log',      'log', 'log'};
axisnames.iter = 'Iteration #';
axisnames.time = 'Time [s]';
axisnames.gradhesscalls = '# gradient calls and Hessian-vector products';
axisnames.gradnorm = 'Gradient norm';
axisnames.timeit = 'timeit [s]';
axisnames.memorytCG_MB = 'memory [MB]';
nmetrics = numel(xmetric);
assert(numel(ymetric) == nmetrics);
for metric = 1 : nmetrics
    figure(metric);
    clf;
    set(gcf, 'Color', 'w');
    for P = 1 : nproblems
        subplot(subplot_rows, subplot_cols, P);
        title(problems{P}.name);
        hold all;
        for S = 1 : nsolvers
            plot([infos{P, S}.(xmetric{metric})], ...
                 [infos{P, S}.(ymetric{metric})], ...
                 'DisplayName', solvers_and_options{S}.name, ...
                 'Marker', '.', 'MarkerSize', 15);
        end
        hold off;
        set(gca, 'XScale', xscale{metric});
        set(gca, 'YScale', yscale{metric});
        if P == 1
		    legend('show');
        end

        ylabel(axisnames.(ymetric{metric}));
        xlabel(axisnames.(xmetric{metric}));
        if ismember(P, [1, 3, 5])
            ylabel(axisnames.(ymetric{metric}));
        end
        if ismember(P, [5, 6])
            xlabel(axisnames.(xmetric{metric}));
        end
        grid on;
        
        % HAND TUNING
        if metric <= 3 && P == 1, ylim([1e-12, 1e2]); end
        if metric <= 3 && P == 2, ylim([1e-12, 1e4]); end
        if metric <= 3 && P == 3, ylim([1e-12, 1e0]); end
        if metric <= 3 && P == 4, ylim([1e-12, 1e3]); end
        if metric <= 3 && P == 5, ylim([1e-12, 1e0]); end
        if metric <= 3 && P == 6, ylim([1e-12, 1e2]); end
        if metric <= 3
            set(gca, 'YTick', [1e-15, 1e-10, 1e-5, 1e0]);
        end
        
    end
end

%%
for metric = 1 : nmetrics
    figure(metric);
    figname = sprintf('compare_solvers_%s_%s_%s', idstring, xmetric{metric}, ymetric{metric});
	savefig([figname, '.fig']);
    pdf_print_code(gcf, [figname, '.pdf'], 14);
end

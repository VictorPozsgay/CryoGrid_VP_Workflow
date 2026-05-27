%========================================================================
% CryoGrid CLUSTERING class K_MEANS
% CLUSTERING class applying K-means clustering to spatial data
%
% K. Aalstad, S. Westermann, Dec 2022
%========================================================================

classdef K_MEANS_categorical < matlab.mixin.Copyable

    properties
        RUN_INFO
        PARA
        CONST
        STATVAR
    end

    methods
        function cluster = provide_PARA(cluster)
            cluster.PARA.number_of_clusters = [];
            cluster.PARA.max_iterations = [];
            cluster.PARA.categorical_variable = [];
            cluster.PARA.cluster_variable_class = [];
            cluster.PARA.cluster_variable_class_index = [];
            cluster.PARA.add2SPATIAL = 0;
        end

        function cluster = provide_STATVAR(cluster)

        end

        function cluster = provide_CONST(cluster)

        end

        function cluster = finalize_init(cluster)

        end

        function cluster = compute_clusters(cluster)
            disp('computing clusters')

            cluster.STATVAR.cluster_number = cluster.RUN_INFO.SPATIAL.STATVAR.key.* NaN;
            cluster.STATVAR.sample_centroid_index = [];
            cluster.STATVAR.key_centroid_index = [];
            if cluster.PARA.add2SPATIAL
                cluster.RUN_INFO.SPATIAL.STATVAR.is_cluster_centroid = cluster.RUN_INFO.SPATIAL.STATVAR.key.*0;
            end

            %determine number of clusters per category
            number_of_clusters_vec = [];
            for categ=min(cluster.RUN_INFO.SPATIAL.STATVAR.(cluster.PARA.categorical_variable)):max(cluster.RUN_INFO.SPATIAL.STATVAR.(cluster.PARA.categorical_variable))

                valid = find(cluster.RUN_INFO.SPATIAL.STATVAR.(cluster.PARA.categorical_variable)==categ);

                number_of_clusters_vec = [number_of_clusters_vec; size(valid,1) ./ size(cluster.RUN_INFO.SPATIAL.STATVAR.key,1) .* cluster.PARA.number_of_clusters];
            end
            residual = number_of_clusters_vec - floor(number_of_clusters_vec);
            number_of_clusters_vec = floor(number_of_clusters_vec);
            [~,ind_residual] = sort(residual, 'descend');
            missing_number_of_cluster = cluster.PARA.number_of_clusters - sum(number_of_clusters_vec);
            number_of_clusters_vec(ind_residual(1:missing_number_of_cluster,1),1) = number_of_clusters_vec(ind_residual(1:missing_number_of_cluster,1),1)+1;

            for categ=min(cluster.RUN_INFO.SPATIAL.STATVAR.(cluster.PARA.categorical_variable)):max(cluster.RUN_INFO.SPATIAL.STATVAR.(cluster.PARA.categorical_variable))

                valid = find(cluster.RUN_INFO.SPATIAL.STATVAR.(cluster.PARA.categorical_variable)==categ);

                number_of_clusters = number_of_clusters_vec(categ); %round(size(valid,1) ./ size(cluster.RUN_INFO.SPATIAL.STATVAR.key,1) .* cluster.PARA.number_of_clusters);
                if number_of_clusters > 0
                    data_cube = [];
                    for i=1:size(cluster.PARA.cluster_variable_class,1)
                        cluster_variable_class = copy(cluster.RUN_INFO.PPROVIDER.CLASSES.(cluster.PARA.cluster_variable_class{i,1}){cluster.PARA.cluster_variable_class_index(i,1),1});
                        fn = fieldnames(cluster.RUN_INFO.SPATIAL.STATVAR);
                        for j=1:size(fn,1)
                            cluster_variable_class.SPATIAL.STATVAR.(fn{j,1}) = cluster.RUN_INFO.SPATIAL.STATVAR.(fn{j,1})(valid,:);
                        end
                        data_cube = [data_cube provide_data(cluster_variable_class)];
                    end

                    Zs = zscore(data_cube,1,1); % Does this make sense for bounded variables, or should you transform first?

                    % Note, may require many iterations (more than standard 1e2) for large Nc
                    rng(size(data_cube,2))
                    [cn,~,~,D] = kmeans(Zs, number_of_clusters, 'MaxIter',cluster.PARA.max_iterations);

                    % Find points closest to centroids within each cluster, henceforth these
                    % points are the sample centroids.
                    indsc=zeros(number_of_clusters,1);% Index (possible range: 1 to total number of points) of
                    ind=(1:size(data_cube,1))';
                    for j=1:number_of_clusters
                        these=(cn==j); % Points in cluster j
                        indc=ind(these); % Indices of points in cluster j
                        Dc=D(these); % Distances to centroid of points in cluster j.
                        here=(Dc==min(Dc)); % Minimum distance to centroid.
                        indsc(j)=min(indc(here)); % "min()" is arbitrary and in case of multiple minima.
                    end
                    if sum(~isnan(cluster.STATVAR.cluster_number))==0
                        cluster.STATVAR.cluster_number(valid,1) = cn;
                    else
                        cluster.STATVAR.cluster_number(valid,1) = cn + max(cluster.STATVAR.cluster_number);
                    end
                    cluster.STATVAR.sample_centroid_index = [cluster.STATVAR.sample_centroid_index; valid(indsc)];
                    cluster.STATVAR.key_centroid_index = [cluster.STATVAR.key_centroid_index; cluster.RUN_INFO.SPATIAL.STATVAR.key(valid(indsc),1)];

                    if cluster.PARA.add2SPATIAL
                        cluster.RUN_INFO.SPATIAL.STATVAR.is_cluster_centroid(valid(indsc),1) = 1;
                    end
                end
            end
        end



        %-------------param file generation-----
        function cluster = param_file_info(cluster)
            cluster = provide_PARA(cluster);

            cluster.PARA.STATVAR = [];
            cluster.PARA.class_category = 'CLUSTERING';

            cluster.PARA.comment.number_of_clusters = {'number of clusters'};

            cluster.PARA.comment.max_iterations = {'maximum number of interations, interrupts k-means algorithm if no convergence is reached'};
            cluster.PARA.default_value.max_iterations = {1000};

            cluster.PARA.comment.cluster_variable_class = {'list of classes providing the data to which the clustering is applied'};
            cluster.PARA.options.cluster_variable_class.name = 'H_LIST';
            cluster.PARA.options.cluster_variable_class.entries_x = {'CLUSTER_RAW_VARIABLES' 'CLUSTER_SLOPE_ASPECT'};

            cluster.PARA.options.cluster_variable_class_index.name = 'H_LIST';
            cluster.PARA.options.cluster_variable_class_index.entries_x = {'1' '1'};

        end

    end
end


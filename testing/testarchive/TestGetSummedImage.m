classdef TestGetSummedImage < matlab.unittest.TestCase
%% Properties
%
% This routine applies tests to falco_get_summed_image.m. At this point we
% are just testing the size of the output array is consistent with supplied
% parameter.
    properties
        mp=Parameters()
    end

%% Tests
%
%  Creates tests:
%
% # *test Image Size* with actal size equal to [mp.Fend.Nxi,mp.Fend.Nxi]
% 
    methods (Test)
        function testImageSize(testCase)
            import matlab.unittest.constraints.HasSize
            act = falco_get_summed_image(testCase.mp);
            testCase.assertThat(act,HasSize([testCase.mp.Fend.Nxi testCase.mp.Fend.Nxi]))
        end
         
    end    
end
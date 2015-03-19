function [ res ] = getTracks( filename )
%GETTRACKS Parses a TrackMate session file and returns the tracks
%   Example usage:
%     tracks = getTracks('140925 test.xml');
PRE_ALLOC = 25000;
spots = zeros(PRE_ALLOC,3);
tracks(PRE_ALLOC).tId = -1;

xDoc = xmlread(filename);

% BUILD THE SPOTS TABLE
% spots = [ sId , sPx, sPy ]
% N.B. See the note below about speeding up the code by using indexing.
xFrames = xDoc.getElementsByTagName('SpotsInFrame');
k = 1;
for i = 0:xFrames.getLength-1
    xFrame = xFrames.item(i);
    xSpotsInFrame = xFrame.getElementsByTagName('Spot');
    for j = 0:xSpotsInFrame.getLength-1
        xSpot = xSpotsInFrame.item(j);
        spots(k,1) = str2int(xSpot.getAttribute('ID'));
        spots(k,2) = str2double(xSpot.getAttribute('POSITION_X'));
        spots(k,3) = str2double(xSpot.getAttribute('POSITION_Y'));
        k = k + 1;
    end
end

% BUILD THE TRACKS TABLE
% tracks(k) = { tId , tSpots }
xTracks = xDoc.getElementsByTagName('Track');
k = 1;
for i = 0:xTracks.getLength-1
    xTrack = xTracks.item(i);
    tracks(k).tId = str2int(xTrack.getAttribute('TRACK_ID'));
    
    xEdgesInTrack = xTrack.getElementsByTagName('Edge');
    
    % Handle the first Spot
    sId = str2int(xEdgesInTrack.item(0).getAttribute('SPOT_SOURCE_ID'));
    [x,y] = lookupSpot(spots, sId);
    tracks(k).tSpots = [x,y];
    
    % Handle the rest of the spots
    for j = 1:xEdgesInTrack.getLength-1
        xEdge = xEdgesInTrack.item(j);
        sId = str2int(xEdge.getAttribute('SPOT_TARGET_ID'));
        [x,y] = lookupSpot(spots, sId);
        tracks(k).tSpots = [tracks(k).tSpots; x y];
    end
    k = k + 1;
end

% Prune the preallocated tracks
res = tracks(find([tracks.tId] > 0));

end

% Note that this can probably be dramatically sped up if we can
% use the id as a row index instead of having to do lookups.
function [x,y] = lookupSpot(spots, sId)
    ix = find(spots(:,1) == sId,1,'first');
    x = spots(ix,2);
    y = spots(ix,3);
end

function res = str2int(cs)
    res = int64(str2double(cs));
end
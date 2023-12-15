function reorderedIndices = moveable_listbox(stringArray)
% Reorder elements of an array through a graphical user interface by dragging

% Create figure and panel on it
f = figure('Position', [300 300 250 350]);
hp = uipanel(f, 'Position', [0 0 1 1]);

% Create listbox with your string array
listbox = uicontrol(hp, 'Style', 'listbox', 'Units', 'normalized', ...
                    'Position', [.2 .4 .6 .5], 'String', stringArray, 'UserData', 1:length(stringArray));

% Create pushbuttons
up_button = uicontrol(hp, 'Style', 'pushbutton', 'Units', 'normalized', ...
                      'Position', [.2 .3 .2 .1], 'String', 'Move Up', ...
                      'Callback', {@moveup_callback, listbox});

down_button = uicontrol(hp, 'Style', 'pushbutton', 'Units', 'normalized', ...
                        'Position', [.6 .3 .2 .1], 'String', 'Move Down', ...
                        'Callback', {@movedown_callback, listbox});

done_button = uicontrol(hp, 'Style', 'pushbutton', 'Units', 'normalized', ...
                        'Position', [.4 .1 .2 .1], 'String', 'Done', ...
                        'Callback', 'uiresume(gcbf)');

    function [] = moveup_callback(~, ~, listbox)
        % User wants to move the currently selected item up
        itemIndex = get(listbox, 'Value');
        if itemIndex > 1
            allItems = get(listbox, 'String');
            currentIndices = get(listbox, 'UserData');
            % Swap items
            [allItems{itemIndex - 1}, allItems{itemIndex}] = deal(allItems{itemIndex}, allItems{itemIndex - 1});
            [currentIndices(itemIndex - 1), currentIndices(itemIndex)] = deal(currentIndices(itemIndex), currentIndices(itemIndex - 1));
            set(listbox, 'String', allItems, 'Value', itemIndex - 1, 'UserData', currentIndices);
        end
    end

    function [] = movedown_callback(~, ~, listbox)
        % User wants to move the currently selected item down
        itemIndex = get(listbox, 'Value');
        allItems = get(listbox, 'String');
        currentIndices = get(listbox, 'UserData');
        if itemIndex < length(allItems)
            % Swap items
            [allItems{itemIndex + 1}, allItems{itemIndex}] = deal(allItems{itemIndex}, allItems{itemIndex + 1});
            [currentIndices(itemIndex + 1), currentIndices(itemIndex)] = deal(currentIndices(itemIndex), currentIndices(itemIndex + 1));
            set(listbox, 'String', allItems, 'Value', itemIndex + 1, 'UserData', currentIndices);
        end
    end

% Wait for user to click "Done" button
uiwait(f);

% Return the reordered indices
reorderedIndices = get(listbox, 'UserData');

% Close the figure
close(f);

end

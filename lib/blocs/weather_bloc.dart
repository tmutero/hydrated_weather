import 'dart:async';

import 'package:meta/meta.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:equatable/equatable.dart';

import 'package:flutter_weather/repositories/repositories.dart';
import 'package:flutter_weather/models/models.dart';

abstract class WeatherEvent extends Equatable {
  const WeatherEvent();

  @override
  List<Object> get props => [];
}

class FetchWeather extends WeatherEvent {
  final String city;

  const FetchWeather({@required this.city}) : assert(city != null);

  @override
  List<Object> get props => [city];
}

class RefreshWeather extends WeatherEvent {
  final String city;

  const RefreshWeather({@required this.city}) : assert(city != null);

  @override
  List<Object> get props => [city];
}

abstract class WeatherState extends Equatable {
  const WeatherState();

  @override
  List<Object> get props => [];
}

class WeatherEmpty extends WeatherState {}

class WeatherLoading extends WeatherState {}

class WeatherLoaded extends WeatherState {
  final Weather weather;

  const WeatherLoaded({@required this.weather}) : assert(weather != null);

  @override
  List<Object> get props => [weather];
}

class WeatherError extends WeatherState {}

class WeatherBloc extends HydratedBloc<WeatherEvent, WeatherState> {
  final WeatherRepository weatherRepository;

  WeatherBloc({@required this.weatherRepository})
      : assert(weatherRepository != null);

  @override
  WeatherState get initialState => super.initialState ?? WeatherEmpty();

  @override
  Stream<WeatherState> mapEventToState(WeatherEvent event) async* {
    if (event is FetchWeather) {
      yield WeatherLoading();
      try {
        final Weather weather = await weatherRepository.getWeather(event.city);
        yield WeatherLoaded(weather: weather);
      } catch (_) {
        yield WeatherError();
      }
    }

    if (event is RefreshWeather) {
      try {
        final Weather weather = await weatherRepository.getWeather(event.city);
        yield WeatherLoaded(weather: weather);
      } catch (_) {}
    }
  }

  @override
  WeatherState fromJson(Map<String, dynamic> json) {
    return WeatherLoaded(
      weather: Weather(
        condition: WeatherCondition.values[json['condition'] as int],
        formattedCondition: json['formattedCondition'],
        minTemp: json['minTemp'],
        temp: json['temp'],
        maxTemp: json['maxTemp'],
        locationId: json['locationId'],
        created: json['created'],
        lastUpdated: DateTime.parse(json['lastUpdated']),
        location: json['location'],
      ),
    );
  }

  @override
  Map<String, dynamic> toJson(WeatherState state) {
    if (state is WeatherLoaded) {
      return {
        'condition': state.weather.condition.index,
        'formattedCondition': state.weather.formattedCondition,
        'minTemp': state.weather.minTemp,
        'temp': state.weather.temp,
        'maxTemp': state.weather.maxTemp,
        'locationId': state.weather.locationId,
        'created': state.weather.created,
        'lastUpdated': state.weather.lastUpdated.toIso8601String(),
        'location': state.weather.location,
      };
    }
    return null;
  }
}
